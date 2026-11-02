# Opt-in checks: temporarily change and restore clipboard contents, recycle only
# disposable test items, and terminate only a listener started by this script.
$ErrorActionPreference = 'Stop'
$OutputEncoding = [Text.UTF8Encoding]::new($false)
[Console]::OutputEncoding = [Text.UTF8Encoding]::new($false)
$repo = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
$bridge = Join-Path $repo 'windows\bridge.ps1'
$testDirectory = Join-Path $repo ('.windows-integration-' + [guid]::NewGuid().ToString('N'))
$job = $null
$clipboard = $null
$clipboardSaved = $false
$bash = Join-Path (Split-Path (Split-Path (Get-Command git.exe).Source)) 'bin\bash.exe'

function Invoke-Bridge([string]$action, [string]$value = '') {
    $env:CF_WINDOWS_VALUE = $value
    $result = & powershell.exe -NoLogo -NoProfile -NonInteractive -STA -ExecutionPolicy Bypass -File $bridge $action
    if ($LASTEXITCODE -ne 0) { throw "Bridge failed: $action" }
    return $result
}

function Invoke-Bash([string]$code) {
    $script = Join-Path $testDirectory 'check.sh'
    [IO.File]::WriteAllText($script, $code.Replace("`r`n", "`n"), [Text.UTF8Encoding]::new($false))
    & $bash --noprofile --norc $script
    if ($LASTEXITCODE -ne 0) { throw 'Git Bash integration check failed.' }
}

try {
    [void][IO.Directory]::CreateDirectory($testDirectory)
    Add-Type -AssemblyName System.Windows.Forms
    Add-Type -AssemblyName System.Drawing
    $clipboard = [Windows.Forms.Clipboard]::GetDataObject()
    $clipboardSaved = $true
    $text = "Unicode: $([char]0x00f1), quotes ' and `$value; [literal]`nsecond line"
    $text | & powershell.exe -NoLogo -NoProfile -NonInteractive -STA -ExecutionPolicy Bypass -File $bridge clipboard-set
    if ($LASTEXITCODE -ne 0) { throw 'Clipboard set failed.' }
    $actual = Invoke-Bridge clipboard-get
    # PowerShell pipelines add a terminating newline; compare the text lines.
    if (($actual -join "`n").TrimEnd() -ne $text) { throw 'Clipboard Unicode round trip failed.' }

    $env:CONFIG_FILES_DIR = $repo
    $env:CF_TEST_TEXT = $text
    $env:CLIPBOARD_HISTORY_DIR = $testDirectory
    Invoke-Bash @'
CONFIG_FILES_DIR=$(cygpath -u "$CONFIG_FILES_DIR")
CLIPBOARD_HISTORY_DIR=$(cygpath -u "$CLIPBOARD_HISTORY_DIR")
source "$CONFIG_FILES_DIR/bashrc.sh"
printf '%s' "$CF_TEST_TEXT" | copy-text-to-clipboard || exit 1
actual=$(paste-text-from-clipboard) || exit 1
actual=${actual//$'\r'/}
[[ $actual == "$CF_TEST_TEXT" ]] && [[ -f "$CLIPBOARD_HISTORY_DIR/1.clipboarditem" ]]
'@

    $bitmap = [Drawing.Bitmap]::new(2, 2)
    try { [Windows.Forms.Clipboard]::SetImage($bitmap) }
    finally { $bitmap.Dispose() }
    $imagePath = Join-Path $testDirectory "image $([char]0x00f1).png"
    Invoke-Bridge clipboard-image $imagePath
    $bytes = [IO.File]::ReadAllBytes($imagePath)
    if ([BitConverter]::ToString($bytes[0..7]) -ne '89-50-4E-47-0D-0A-1A-0A') { throw 'Invalid PNG.' }

    $trashPath = Join-Path $testDirectory "trash $([char]0x00f1) ' [literal].txt"
    [IO.File]::WriteAllText($trashPath, 'disposable test file')
    Invoke-Bridge trash $trashPath
    if (Test-Path -LiteralPath $trashPath) { throw 'Recycle Bin test failed.' }
    $trashDirectory = Join-Path $testDirectory 'disposable directory'
    [void][IO.Directory]::CreateDirectory($trashDirectory)
    [IO.File]::WriteAllText((Join-Path $trashDirectory 'child.txt'), 'test')
    Invoke-Bridge trash $trashDirectory
    if (Test-Path -LiteralPath $trashDirectory) { throw 'Directory recycle test failed.' }

    $addresses = @(Invoke-Bridge ips '--all')
    if (-not $addresses.Count) { throw 'No IPv4 addresses returned.' }
    [void][Net.IPAddress]::Parse((Invoke-Bridge ips '--primary'))

    $job = Start-Job -ScriptBlock {
        $listener = [Net.Sockets.TcpListener]::new([Net.IPAddress]::Loopback, 0)
        $listener.Start()
        Write-Output "$PID $($listener.LocalEndpoint.Port)"
        try { Start-Sleep -Seconds 90 } finally { $listener.Stop() }
    }
    $listenerInfo = $null
    for ($attempt = 0; $attempt -lt 40; $attempt++) {
        $listenerInfo = Receive-Job $job
        if ($listenerInfo) { break }
        Start-Sleep -Milliseconds 250
    }
    if (-not $listenerInfo) { throw 'Listener did not start.' }
    $listenerPid, $listenerPort = "$listenerInfo".Split(' ')
    $owners = @(Invoke-Bridge port-owner $listenerPort)
    if (-not ($owners -match "^$listenerPid ")) { throw 'Port owner lookup failed.' }
    # Exercise the public Git Bash function, including Windows PID handling.
    $env:CONFIG_FILES_DIR = $repo
    $env:CF_TEST_PORT = $listenerPort
    Invoke-Bash @'
CONFIG_FILES_DIR=$(cygpath -u "$CONFIG_FILES_DIR")
source "$CONFIG_FILES_DIR/bashrc.sh"
kill-port "$CF_TEST_PORT" --force
'@
    Start-Sleep -Milliseconds 250
    if (Get-Process -Id $listenerPid -ErrorAction SilentlyContinue) { throw 'Listener still running.' }
    'PASS: clipboard text/image, Recycle Bin file/directory, IPv4 and listener inspection/termination.'
} finally {
    if ($clipboardSaved) {
        if ($null -ne $clipboard) { [Windows.Forms.Clipboard]::SetDataObject($clipboard, $true) }
        else { [Windows.Forms.Clipboard]::Clear() }
    }
    if ($null -ne $job) { Stop-Job $job; Remove-Job $job -Force }
    $resolvedTestDirectory = [IO.Path]::GetFullPath($testDirectory)
    if ($resolvedTestDirectory.StartsWith($repo + [IO.Path]::DirectorySeparatorChar) -and
        (Split-Path $resolvedTestDirectory -Leaf) -like '.windows-integration-*') {
        Remove-Item -LiteralPath $resolvedTestDirectory -Recurse -Force
    }
}
