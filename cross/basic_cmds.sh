
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
