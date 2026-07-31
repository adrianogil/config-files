alias ips-net='ifconfig | grep net'
function ips()
{
    ifconfig | grep -E "([0-9]{1,3}\.){3}[0-9]{1,3}" | grep -v 127.0.0.1 | awk '{ print $2 }' | cut -f2 -d: | head -n1
}

function ips-external()
{
    curl -4 ifconfig.me
}

# config-tools port-owner: Show the process listening on a TCP or UDP port
function port-owner()
{
    local port="${1:-}"
    local output=""

    if [[ ! $port =~ ^[0-9]+$ ]] || (( port < 1 || port > 65535 )); then
        printf 'Usage: port-owner <port (1-65535)>\n' >&2
        return 2
    fi

    if command -v lsof >/dev/null 2>&1; then
        output=$(
            {
                lsof -nP -iTCP:"$port" -sTCP:LISTEN
                lsof -nP -iUDP:"$port"
            } 2>/dev/null | awk '$0 !~ /^COMMAND[[:space:]]/ || !seen_header++'
        )
    elif command -v ss >/dev/null 2>&1; then
        output=$(ss -H -lntup "sport = :$port" 2>/dev/null)
    else
        printf 'port-owner: install lsof or ss to inspect listening ports\n' >&2
        return 127
    fi

    if [[ -z $output ]]; then
        printf 'port-owner: no process is listening on port %s\n' "$port" >&2
        return 1
    fi

    printf '%s\n' "$output"
}

SSH_DEFAULT_PORT=7375

alias ssh2moi='ssh -p $SSH_DEFAULT_PORT'

function serverssh()
{
    if [ -z "$1" ]
    then
        ssh_port=$SSH_DEFAULT_PORT
    else
        ssh_port=$1
    fi
    echo "Starting sshd server using port "$ssh_port" on IP: "$(ips)
    sshd -p $ssh_port
}
