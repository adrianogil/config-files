function ps-suspend()
{
    $PID=$1
    kill -SIGSTOP $PID
}

function ps-resume()
{
    $PID=$1
    kill -SIGCONT $PID
}

function ps-pick()
{
    target_pid=$(ps aux | default-fuzzy-finder | awk '{print $2}')
    echo $target_pid | copy-text-to-clipboard
    echo $target_pid
}

function ps-monitor()
{
    top -pid $(ps-pick)
}

alias k9="sudo kill -9 "

function ps-from-port()
{
	target_port=$1
	lsof -i :${target_port}
}

function _open-files-run-lsof()
{
    local description=$1
    shift

    local output
    local lsof_status=0

    output=$(lsof -nP "$@" 2>/dev/null) || lsof_status=$?
    if [ -z "${output}" ]
    then
        printf 'open-files: no open files found for %s\n' "${description}" >&2
        [ "${lsof_status}" -ne 0 ] || lsof_status=1
        return "${lsof_status}"
    fi

    printf '%s\n' "${output}"
}

# config-tools open-files: Show processes using a path or files opened by a process
function open-files()
{
    local target_path
    local target_pid
    local process_list
    local process_selection

    if ! command -v lsof >/dev/null 2>&1
    then
        printf 'open-files: lsof is required\n' >&2
        return 127
    fi

    case "$#:${1:-}" in
        0:)
            process_list=$(ps -Ao pid=,user=,comm= 2>/dev/null)
            if [ -z "${process_list}" ]
            then
                printf 'open-files: could not list processes\n' >&2
                return 1
            fi

            process_selection=$(
                printf '%s\n' "${process_list}" |
                    default-fuzzy-finder \
                        --prompt='process> ' \
                        --header='PID USER COMMAND'
            ) || return 1

            target_pid=$(printf '%s\n' "${process_selection}" | awk '{ print $1 }')
            ;;
        1:-h|1:--help)
            printf 'Usage: open-files [path]\n       open-files --pid <pid>\n'
            return 0
            ;;
        1:*)
            target_path=$1
            if [[ ! -e $target_path && ! -L $target_path ]]
            then
                printf 'open-files: %s: No such file or directory\n' "${target_path}" >&2
                return 1
            fi
            _open-files-run-lsof "${target_path}" -- "${target_path}"
            return
            ;;
        2:--pid)
            target_pid=$2
            ;;
        2:--)
            target_path=$2
            if [[ ! -e $target_path && ! -L $target_path ]]
            then
                printf 'open-files: %s: No such file or directory\n' "${target_path}" >&2
                return 1
            fi
            _open-files-run-lsof "${target_path}" -- "${target_path}"
            return
            ;;
        *)
            printf 'Usage: open-files [path]\n       open-files --pid <pid>\n' >&2
            return 2
            ;;
    esac

    if [[ ! $target_pid =~ ^[1-9][0-9]*$ ]]
    then
        printf 'open-files: PID must be a positive integer\n' >&2
        return 2
    fi

    _open-files-run-lsof "PID ${target_pid}" -p "${target_pid}"
}
