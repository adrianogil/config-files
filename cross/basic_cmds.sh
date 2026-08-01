
# config-tools cf-cp-fz: Copy by selecting target file using default-fuzzy-finder
function cf-cp-fz()
{
	destination_file=$1
	target_file=$(find . | default-fuzzy-finder)

	cp ${target_file} ${destination_file}
	echo "Copied "${target_file}" as "${destination_file}
}
alias cp-fz="cf-cp-fz"

# config-tools myvars: List all variables names and their current values
function myvars()
{
	printenv | less
}

# config-tools which-shell: Print the shell name
function which-shell()
{
    ps -p $$ -o pid,comm=
}

# config-tools uuid-new: Generate one or more UUIDs
function uuid-new()
{
    local count="${1:-1}"
    local generator=""
    local index=0

    if [[ $# -gt 1 || ! $count =~ ^[1-9][0-9]*$ ]]; then
        printf 'Usage: uuid-new [count]\n' >&2
        return 2
    fi

    if command -v uuidgen >/dev/null 2>&1; then
        generator=uuidgen
    elif command -v python3 >/dev/null 2>&1; then
        generator=python3
    elif [[ -r /proc/sys/kernel/random/uuid ]]; then
        generator=proc
    else
        printf 'uuid-new: install uuidgen or Python 3 to generate UUIDs\n' >&2
        return 127
    fi

    for ((index = 0; index < count; index++)); do
        case "$generator" in
            uuidgen) uuidgen | tr '[:upper:]' '[:lower:]' ;;
            python3) python3 -c 'import uuid; print(uuid.uuid4())' ;;
            proc) cat /proc/sys/kernel/random/uuid ;;
        esac
    done
}

# config-tools chmod-explain: Explain numeric or symbolic file permissions
function chmod-explain()
{
    if [[ $# -ne 1 ]]; then
        printf 'Usage: chmod-explain <mode>\n' >&2
        return 2
    fi

    if ! command -v python3 >/dev/null 2>&1; then
        printf 'chmod-explain: Python 3 is required\n' >&2
        return 127
    fi

    if [[ -z ${CONFIG_FILES_DIR:-} ]]; then
        printf 'chmod-explain: CONFIG_FILES_DIR is not set\n' >&2
        return 1
    fi

    python3 "$CONFIG_FILES_DIR/python/clitools/chmod_explain.py" "$1"
}

function _timezone_choices()
{
    printf '%s\n' \
        'Manaus|America/Manaus' \
        'SP|America/Sao_Paulo' \
        'BRT|America/Sao_Paulo' \
        'EST|Etc/GMT+5' \
        'USA Chicago|America/Chicago' \
        'South Korea|Asia/Seoul' \
        'China|Asia/Shanghai'
}

function _timezone_select()
{
    local prompt=$1
    local selection=""

    selection=$(
        _timezone_choices \
            | default-fuzzy-finder \
                --prompt="$prompt" --delimiter='|' --with-nth=1 \
                --height=40% --reverse
    ) || {
        printf 'timezone-convert: time zone selection cancelled\n' >&2
        return 1
    }

    [[ -n $selection && $selection == *'|'* ]] || return 1
    printf '%s\n' "${selection#*|}"
}

# config-tools timezone-convert: Convert a datetime between time zones
function timezone-convert()
{
    local datetime_value="${1:-}"
    local source_zone="${2:-}"
    local target_zone="${3:-}"

    if [[ $# -lt 1 || $# -gt 3 || -z $datetime_value ]]; then
        printf 'Usage: timezone-convert <datetime> [from-zone] [to-zone]\n' >&2
        return 2
    fi

    if [[ -z $source_zone ]]; then
        source_zone=$(_timezone_select 'from timezone> ') || return 1
    fi

    if [[ -z $target_zone ]]; then
        target_zone=$(_timezone_select 'to timezone> ') || return 1
    fi

    if ! command -v python3 >/dev/null 2>&1; then
        printf 'timezone-convert: Python 3 is required\n' >&2
        return 127
    fi

    if [[ -z ${CONFIG_FILES_DIR:-} ]]; then
        printf 'timezone-convert: CONFIG_FILES_DIR is not set\n' >&2
        return 1
    fi

    python3 "$CONFIG_FILES_DIR/python/clitools/timezone_convert.py" \
        "$datetime_value" "$source_zone" "$target_zone"
}
