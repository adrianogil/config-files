param(
    [Parameter(Mandatory = $true)]
    [ValidateSet('clipboard-set', 'clipboard-get', 'clipboard-image', 'open', 'trash', 'ips', 'port-owner', 'kill-pids')]
    [string]$Action
)

$ErrorActionPreference = 'Stop'
[Console]::InputEncoding = [System.Text.UTF8Encoding]::new($false)
[Console]::OutputEncoding = [System.Text.UTF8Encoding]::new($false)
$value = $env:CF_WINDOWS_VALUE

try {
    switch ($Action) {
        'clipboard-set' {
            Add-Type -AssemblyName System.Windows.Forms
            $content = [Console]::In.ReadToEnd()
            if ($content.Length) { [System.Windows.Forms.Clipboard]::SetText($content) }
            else { [System.Windows.Forms.Clipboard]::Clear() }
        }
        'clipboard-get' {
            Add-Type -AssemblyName System.Windows.Forms
            [Console]::Write([System.Windows.Forms.Clipboard]::GetText())
        }
        'clipboard-image' {
            Add-Type -AssemblyName System.Windows.Forms
            Add-Type -AssemblyName System.Drawing
            $image = [System.Windows.Forms.Clipboard]::GetImage()
            if ($null -eq $image) { throw 'The clipboard does not contain an image.' }
            try { $image.Save($value, [System.Drawing.Imaging.ImageFormat]::Png) }
            finally { $image.Dispose() }
        }
        'open' {
            $info = [System.Diagnostics.ProcessStartInfo]::new()
            $info.FileName = $value
            $info.UseShellExecute = $true
            [void][System.Diagnostics.Process]::Start($info)
        }
        'trash' {
            $path = [System.IO.Path]::GetFullPath($value)
            $root = [System.IO.Path]::GetPathRoot($path)
            if ($path.TrimEnd('\') -eq $root.TrimEnd('\') -or
                $path.TrimEnd('\') -eq $env:USERPROFILE.TrimEnd('\')) {
                throw "Refusing to trash protected path: $path"
            }
            if (-not (Test-Path -LiteralPath $path)) { throw "Path does not exist: $path" }
            Add-Type -AssemblyName Microsoft.VisualBasic
            $ui = [Microsoft.VisualBasic.FileIO.UIOption]::OnlyErrorDialogs
            $recycle = [Microsoft.VisualBasic.FileIO.RecycleOption]::SendToRecycleBin
            $cancel = [Microsoft.VisualBasic.FileIO.UICancelOption]::ThrowException
            if ([System.IO.Directory]::Exists($path)) {
                [Microsoft.VisualBasic.FileIO.FileSystem]::DeleteDirectory($path, $ui, $recycle, $cancel)
            } else {
                [Microsoft.VisualBasic.FileIO.FileSystem]::DeleteFile($path, $ui, $recycle, $cancel)
            }
        }
        'ips' {
            $addresses = @(Get-NetIPAddress -AddressFamily IPv4 |
                Where-Object { $_.IPAddress -ne '127.0.0.1' -and $_.AddressState -eq 'Preferred' })
            if ($value -eq '--primary') {
                $route = Get-NetRoute -AddressFamily IPv4 -DestinationPrefix '0.0.0.0/0' |
                    Sort-Object @{ Expression = {
                        $_.RouteMetric + (Get-NetIPInterface -AddressFamily IPv4 -InterfaceIndex $_.InterfaceIndex).InterfaceMetric
                    } } | Select-Object -First 1
                if ($null -eq $route) { throw 'No default IPv4 route found.' }
                $addresses = @($addresses | Where-Object InterfaceIndex -eq $route.InterfaceIndex)
            }
            if (-not $addresses.Count) { throw 'No local IPv4 address found.' }
            if ($value -eq '--all') { $addresses.IPAddress }
            else { $addresses[0].IPAddress }
        }
        'port-owner' {
            $port = 0
            if (-not [int]::TryParse($value, [ref]$port) -or $port -lt 1 -or $port -gt 65535) {
                throw 'Port must be an integer between 1 and 65535.'
            }
            $listeners = @(Get-NetTCPConnection -State Listen -ErrorAction SilentlyContinue |
                Where-Object LocalPort -eq $port)
            $listeners += @(Get-NetUDPEndpoint -ErrorAction SilentlyContinue | Where-Object LocalPort -eq $port)
            $owners = @($listeners | Select-Object -ExpandProperty OwningProcess -Unique)
            if (-not $owners.Count) { throw "No process is listening on port $port" }
            'PID NAME'
            foreach ($owner in $owners) {
                $process = Get-Process -Id $owner -ErrorAction Stop
                '{0} {1}' -f $owner, $process.ProcessName
            }
        }
        'kill-pids' {
            if ($value -notmatch '^\d+(,\d+)*$') { throw 'Expected a comma-separated list of PIDs.' }
            foreach ($owner in $value.Split(',')) {
                Stop-Process -Id ([int]$owner) -ErrorAction Stop
                "Stopped PID $owner"
            }
        }
    }
    exit 0
} catch {
    [Console]::Error.WriteLine("${Action}: $($_.Exception.Message)")
    exit 1
}
