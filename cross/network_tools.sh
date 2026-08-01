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

# config-tools wait-port: Wait until a TCP host and port become reachable
function wait-port()
{
    local host="${1:-}"
    local port="${2:-}"
    local timeout="${3:-30}"
    local start_time=$SECONDS
    local probe=""

    if [[ $# -lt 2 || $# -gt 3 || -z $host || ! $port =~ ^[0-9]+$ ]] \
        || (( port < 1 || port > 65535 )) \
        || [[ ! $timeout =~ ^[1-9][0-9]*$ ]]; then
        printf 'Usage: wait-port <host> <port (1-65535)> [timeout-seconds]\n' >&2
        return 2
    fi

    if command -v nc >/dev/null 2>&1; then
        probe=nc
    elif command -v python3 >/dev/null 2>&1; then
        probe=python3
    else
        printf 'wait-port: install nc or Python 3 to probe TCP ports\n' >&2
        return 127
    fi

    while (( SECONDS - start_time < timeout )); do
        if [[ $probe == nc ]]; then
            nc -z -w 1 "$host" "$port" >/dev/null 2>&1
        else
            python3 -c 'import socket, sys
with socket.create_connection((sys.argv[1], int(sys.argv[2])), timeout=1):
    pass' "$host" "$port" >/dev/null 2>&1
        fi

        if [[ $? -eq 0 ]]; then
            printf '%s:%s is reachable.\n' "$host" "$port"
            return 0
        fi

        sleep 1
    done

    printf 'wait-port: timed out after %s seconds waiting for %s:%s\n' \
        "$timeout" "$host" "$port" >&2
    return 1
}

# config-tools serve-dir: Serve the current directory over HTTP
function serve-dir()
{
    local port="${1:-8000}"
    local bind_address="${SERVE_DIR_BIND:-127.0.0.1}"
    local python_command=""

    if [[ $# -gt 1 || ! $port =~ ^[0-9]+$ ]] || (( port < 1 || port > 65535 )); then
        printf 'Usage: serve-dir [port (1-65535)]\n' >&2
        return 2
    fi

    if command -v python3 >/dev/null 2>&1; then
        python_command=python3
    elif command -v python >/dev/null 2>&1 && python -c 'import http.server' >/dev/null 2>&1; then
        python_command=python
    else
        printf 'serve-dir: Python 3 is required\n' >&2
        return 127
    fi

    printf 'Serving %s at http://%s:%s/ (Ctrl-C to stop)\n' \
        "$PWD" "$bind_address" "$port"
    "$python_command" -m http.server "$port" --bind "$bind_address"
}

# config-tools weather-now: Show a concise current weather report
function weather-now()
{
    local location="$*"
    local encoded_location=""
    local weather_url=""

    if ! command -v curl >/dev/null 2>&1; then
        printf 'weather-now: curl is required\n' >&2
        return 127
    fi

    encoded_location=${location// /+}
    weather_url="https://wttr.is/${encoded_location}?m&format=4"

    if ! curl --fail --silent --show-error --location --max-time 15 "$weather_url"; then
        printf 'weather-now: unable to retrieve weather data\n' >&2
        return 1
    fi
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
