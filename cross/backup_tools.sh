TMP_BKP_DIR=${TMP_BKP_DIR:-/tmp/backup}


function _bkp-pick-target()
{
    local prompt=$1
    local selection

    selection=$(
        find . -mindepth 1 \
            \( -path './.git' -o -path './.git/*' -o -name '.bkp_*' \) \
            -prune -o -print |
            sort |
            default-fuzzy-finder --prompt="${prompt}"
    ) || return 1

    if [ -z "${selection}" ]
    then
        printf 'Backup target selection cancelled.\n' >&2
        return 1
    fi

    printf '%s\n' "${selection}"
}

function _bkp-record-history()
{
    local target=$1
    local snapshot_path=$2
    local stored_path=$3
    local target_type=$4

    if command -v python3 >/dev/null 2>&1 && [[ -n ${CONFIG_FILES_DIR:-} ]]
    then
        python3 "$CONFIG_FILES_DIR/python/clitools/backup_history.py" record \
            "$TMP_BKP_DIR" "$target" "$snapshot_path" "$stored_path" \
            "$target_type" ||
            printf 'bkp: warning: could not update backup history\n' >&2
    fi
}

function _bkp-latest-local-snapshot()
{
    local target=$1
    local target_name
    local target_directory

    target_name=$(basename "$target")
    target_directory=$(dirname "$target")

    find "$target_directory" -maxdepth 1 -name ".bkp_${target_name}.*" \
        -print 2>/dev/null | sort | tail -n 1
}

function _bkp-latest-stored-snapshot()
{
    local target_name=$1

    [ -d "$TMP_BKP_DIR" ] || return 0
    find "$TMP_BKP_DIR" -mindepth 4 -maxdepth 4 -name "$target_name" \
        -print 2>/dev/null | sort | tail -n 1
}


# config-tools bkp: Back up a file or directory
function bkp()
{
    local target="${1:-}"
    local current_date_prefix
    local current_date_path
    local dated_backup_directory
    local target_name
    local target_directory
    local snapshot_path
    local stored_path
    local target_type=file

    if [ "$#" -gt 1 ]
    then
        printf 'Usage: bkp [target]\n' >&2
        return 2
    fi

    if [ -z "${target}" ]
    then
        target=$(_bkp-pick-target 'backup> ') || return 1
    fi

    if [[ ! -e $target && ! -L $target ]]
    then
        printf 'bkp: %s: No such file or directory\n' "$target" >&2
        return 1
    fi

    current_date_prefix=$(date +%Y%m%d%H%M%S)
    current_date_path=$(date +%Y/%m/%Y.%mW%W)
    dated_backup_directory="$TMP_BKP_DIR/$current_date_path"
    target_name=$(basename "$target")
    target_directory=$(dirname "$target")
    snapshot_path="$target_directory/.bkp_${target_name}.${current_date_prefix}"
    stored_path="$dated_backup_directory/$target_name"

    mkdir -p "$dated_backup_directory" || return 1

    if [ -d "$target" ]
    then
        target_type=directory
        printf 'Backing up directory %s\n' "$target"
        cp -R "$target" "$dated_backup_directory/" || return 1
        cp -R "$target" "$snapshot_path" || return 1
    else
        printf 'Backing up file %s\n' "$target"
        cp "$target" "$dated_backup_directory/" || return 1
        cp "$target" "$snapshot_path" || return 1
    fi

    _bkp-record-history "$target" "$snapshot_path" "$stored_path" "$target_type"
}

# config-tools bkp-restore: Restore the latest backup of a file or directory
function bkp-restore()
{
    local target="${1:-}"
    local target_name
    local snapshot_path

    if [ "$#" -gt 1 ]
    then
        printf 'Usage: bkp-restore [target]\n' >&2
        return 2
    fi

    if [ -z "${target}" ]
    then
        target=$(_bkp-pick-target 'restore> ') || return 1
    fi

    target_name=$(basename "$target")
    snapshot_path=$(_bkp-latest-local-snapshot "$target")
    if [ -z "${snapshot_path}" ]
    then
        snapshot_path=$(_bkp-latest-stored-snapshot "$target_name")
    fi

    if [ -z "${snapshot_path}" ] || [[ ! -e $snapshot_path && ! -L $snapshot_path ]]
    then
        printf 'No backup found for %s\n' "$target" >&2
        return 1
    fi

    if [ -d "$snapshot_path" ]
    then
        if [[ -e $target && ! -d $target ]]
        then
            printf 'bkp-restore: cannot restore a directory over %s\n' "$target" >&2
            return 1
        fi

        printf 'Restoring directory %s\n' "$target"
        if [ -d "$target" ]
        then
            cp -R "$snapshot_path/." "$target/"
        else
            cp -R "$snapshot_path" "$target"
        fi
    else
        if [ -d "$target" ]
        then
            printf 'bkp-restore: cannot restore a file over directory %s\n' "$target" >&2
            return 1
        fi

        printf 'Restoring file %s\n' "$target"
        cp "$snapshot_path" "$target"
    fi
}

# config-tools bkp-last: List the most recently backed-up items
function bkp-last()
{
    local count="${1:-10}"

    if [ "$#" -gt 1 ] || [[ ! $count =~ ^[1-9][0-9]*$ ]]
    then
        printf 'Usage: bkp-last [count]\n' >&2
        return 2
    fi
    if ! command -v python3 >/dev/null 2>&1
    then
        printf 'bkp-last: Python 3 is required\n' >&2
        return 127
    fi
    if [[ -z ${CONFIG_FILES_DIR:-} ]]
    then
        printf 'bkp-last: CONFIG_FILES_DIR is not set\n' >&2
        return 1
    fi

    python3 "$CONFIG_FILES_DIR/python/clitools/backup_history.py" list \
        "$TMP_BKP_DIR" "$count"
}
