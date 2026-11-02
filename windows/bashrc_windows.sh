# Pass user values as environment data, never executable PowerShell source.
function _windows-call()
{
    if ! command -v powershell.exe >/dev/null 2>&1; then
        printf 'Windows integration requires powershell.exe on PATH.\n' >&2
        return 127
    fi
    local action=$1
    local value=${2:-}
    MSYS2_ARG_CONV_EXCL='*' CF_WINDOWS_VALUE="$value" powershell.exe \
        -NoLogo -NoProfile -NonInteractive -STA -ExecutionPolicy Bypass \
        -File "$(cygpath -w "$CONFIG_FILES_DIR/windows/bridge.ps1")" "$action"
}

function _clipboard-system-set() { _windows-call clipboard-set; }
function paste-text-from-clipboard() { _windows-call clipboard-get; }
function _clipboard-system-image-get()
{
    _windows-call clipboard-image "$(cygpath -aw "$1")"
}

function open()
{
    if [[ $# -ne 1 ]]; then
        printf 'Usage: open <file|directory|URL>\n' >&2
        return 2
    fi
    case "$1" in
        http://*|https://*|mailto:*) _windows-call open "$1" ;;
        *) _windows-call open "$(cygpath -aw "$1")" ;;
    esac
}

function _windows-trash()
{
    local target
    local native_path
    for target in "$@"; do
        native_path=$(cygpath -aw "$target") || return 1
        if [[ $native_path == "$(cygpath -aw /)" ]]; then
            printf 'trash: refusing to trash the Git Bash root: %s\n' "$target" >&2
            return 1
        fi
        _windows-call trash "$native_path" || return 1
        printf 'Trashed: %s\n' "$target"
    done
}

function _windows-ips()
{
    if [[ $# -gt 1 ]]; then
        printf 'Usage: ips [--all|--primary]\n' >&2
        return 2
    fi
    case "${1:-}" in
        ''|--all|--primary) _windows-call ips "${1:-}" ;;
        -h|--help) printf 'Usage: ips [--all|--primary]\n' ;;
        *) printf 'Usage: ips [--all|--primary]\n' >&2; return 2 ;;
    esac
}

function _windows-kill-port()
{
    local port=$1
    local force=${2:-}
    local owners
    local answer
    owners=$(_windows-call port-owner "$port") || return $?
    printf '%s\n' "$owners"
    if [[ $force != --force ]]; then
        printf 'Terminate these processes? [y/N] ' >&2
        IFS= read -r answer
        case "$answer" in
            y|Y|yes|YES|Yes) ;;
            *) printf 'Cancelled.\n'; return 1 ;;
        esac
    fi
    # Only terminate the PIDs displayed before confirmation.
    _windows-call kill-pids "$(printf '%s\n' "$owners" | tr -d '\r' | awk 'NR > 1 { print $1 }' | paste -sd, -)"
}

alias c='code'
alias cw='code -n'
