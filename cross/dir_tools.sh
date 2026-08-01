function workspace()
{
    cd ${WORKSPACE_DIR}
}

# Directory creation
function md()
{
    echo 'Creating directory '$1
    mkdir -p $1
}

function mdd()
{
    echo 'Creating directory '$1
    mkdir -p $1
    echo 'Entrying directory '$1
    cd $1
}

# config-tools mddate: Create a directory with current date
function mddate()
{
    target_directory=$(date +%Y%m%d%H%M)

    echo 'Creating directory '${target_directory}
    mkdir -p ${target_directory}
    echo 'Entrying directory '${target_directory}
    cd ${target_directory}
}

function mdweek()
{
    target_directory=$(date +%Y/%m/%Y.%mW%W)

    echo 'Creating directory '${target_directory}
    mkdir -p ${target_directory}
    echo 'Entrying directory '${target_directory}
    cd ${target_directory}

}

function cdweek()
{
    target_directory=$(date +%Y/%m/%Y.%mW%W)

    echo 'Entrying directory '${target_directory}
    cd ${target_directory}

}

# config-tools cd_up: Go up n directories
function cd_up() {
  cd $(printf "%0.s../" $(seq 1 $1 ));
}
alias 'cd..'='cd_up'

# Navigation
alias ..="cd .."
alias ...="cd ../.."
alias ....="cd ../../.."
alias .....="cd ../../../.."

# config-tools cdk: Enter a directory from using default-fuzzy-finder
function cdk()
{
    cd "$(find . -type d -regex '\./[^.]*$' | default-fuzzy-finder)"
}

function _list_parents() {
    local path="$PWD"
    while [ "$path" != "/" ] && [ -n "$path" ]; do
        echo "$path"
        path="${path%/*}"
    done
    echo "/"
}

# config-tools cdp: Fuzzy-search and enter a parent directory
function cdp() {
    local parents
    parents=$(_list_parents | default-fuzzy-finder)
    cd "$parents"
}

# config-tools dir-depth: Report the deepest directory nesting
function dir-depth()
{
    local target_directory="${1:-.}"

    if [[ $# -gt 1 ]]; then
        printf 'Usage: dir-depth [directory]\n' >&2
        return 2
    fi

    if [[ ! -d $target_directory ]]; then
        printf 'dir-depth: %s: Not a directory\n' "$target_directory" >&2
        return 1
    fi

    if ! command -v python3 >/dev/null 2>&1; then
        printf 'dir-depth: Python 3 is required\n' >&2
        return 127
    fi

    if [[ -z ${CONFIG_FILES_DIR:-} ]]; then
        printf 'dir-depth: CONFIG_FILES_DIR is not set\n' >&2
        return 1
    fi

    python3 "$CONFIG_FILES_DIR/python/clitools/dir_depth.py" "$target_directory"
}
