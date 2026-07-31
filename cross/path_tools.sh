
function abspath() {
    # generate absolute path from relative path
    # $1     : relative filename
    # return : absolute path
    if [ -d "$1" ]; then
        # dir
        (cd "$1"; pwd)
    elif [ -f "$1" ]; then
        # file
        if [[ $1 = /* ]]; then
            echo "$1"
        elif [[ $1 == */* ]]; then
            echo "$(cd "${1%/*}"; pwd)/${1##*/}"
        else
            echo "$(pwd)/$1"
        fi
    fi
}

function path-show() {
    echo -e ${PATH//:/\\n}
}

# config-tools path-dedupe: Remove duplicate entries from PATH
function path-dedupe()
{
    local remaining="${PATH}:"
    local entry=""
    local existing=""
    local duplicate=0
    local removed=0
    local IFS=:
    local -a unique_entries=()

    while [[ $remaining == *:* ]]; do
        entry=${remaining%%:*}
        remaining=${remaining#*:}
        duplicate=0

        for existing in "${unique_entries[@]}"; do
            if [[ $entry == "$existing" ]]; then
                duplicate=1
                break
            fi
        done

        if (( duplicate )); then
            removed=$((removed + 1))
        else
            unique_entries+=("$entry")
        fi
    done

    PATH="${unique_entries[*]}"
    export PATH

    printf 'Removed %d duplicate PATH entr%s.\n' \
        "$removed" "$([[ $removed -eq 1 ]] && printf 'y' || printf 'ies')"
    printf '%s\n' "$PATH"
}

function pwdcp()
{
    if [[ $0 == *termux* ]]; then
        pwd | termux-clipboard-set
    else
        pwd | copy-text-to-clipboard
    fi
}
