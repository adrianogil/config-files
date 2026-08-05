# config-tools package-owner: Identify the package manager and package owning a file or command
function package-owner()
{
    if [[ $# -ne 1 ]]; then
        printf 'Usage: package-owner <file-or-command>\n' >&2
        return 2
    fi

    if ! command -v python3 >/dev/null 2>&1; then
        printf 'package-owner: Python 3 is required\n' >&2
        return 127
    fi

    if [[ -z ${CONFIG_FILES_DIR:-} ]]; then
        printf 'package-owner: CONFIG_FILES_DIR is not set\n' >&2
        return 1
    fi

    python3 "$CONFIG_FILES_DIR/python/clitools/package_owner.py" "$1"
}
