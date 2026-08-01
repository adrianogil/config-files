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

# config-tools kill-port: Terminate the process listening on a TCP or UDP port
function kill-port()
{
    local port="${1:-}"
    local force="${2:-}"
    local pids=""
    local pid=""
    local answer=""
    local kill_status=0

    if [[ $# -lt 1 || $# -gt 2 || ! $port =~ ^[0-9]+$ ]] \
        || (( port < 1 || port > 65535 )) \
        || [[ -n $force && $force != --force ]]; then
        printf 'Usage: kill-port <port (1-65535)> [--force]\n' >&2
        return 2
    fi

    if command -v lsof >/dev/null 2>&1; then
        pids=$(
            {
                lsof -tiTCP:"$port" -sTCP:LISTEN
                lsof -tiUDP:"$port"
            } 2>/dev/null | sort -u
        )
    elif command -v fuser >/dev/null 2>&1; then
        pids=$(
            {
                fuser "$port/tcp"
                fuser "$port/udp"
            } 2>/dev/null | tr ' ' '\n' | awk '/^[0-9]+$/' | sort -u
        )
    else
        printf 'kill-port: install lsof or fuser to inspect listening ports\n' >&2
        return 127
    fi

    if [[ -z $pids ]]; then
        printf 'kill-port: no process is listening on port %s\n' "$port" >&2
        return 1
    fi

    printf 'Processes listening on port %s:\n' "$port"
    ps -p "$(printf '%s\n' "$pids" | paste -sd, -)" -o pid=,user=,comm=

    if [[ $force != --force ]]; then
        printf 'Terminate these processes? [y/N] ' >&2
        IFS= read -r answer
        case "$answer" in
            y|Y|yes|YES|Yes) ;;
            *)
                printf 'Cancelled.\n'
                return 1
                ;;
        esac
    fi

    while IFS= read -r pid; do
        [[ -z $pid ]] && continue
        kill "$pid" || kill_status=1
    done <<< "$pids"

    [[ $kill_status -eq 0 ]] || return 1
    printf 'Sent SIGTERM to PID(s): %s\n' "$(printf '%s' "$pids" | tr '\n' ' ')"
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

# config-tools ssl-expiry: Show TLS certificate validity and remaining days
function ssl-expiry()
{
    local domain="${1:-}"
    local port="${2:-443}"
    local certificate=""
    local details=""
    local end_date=""
    local end_epoch=""
    local now_epoch=""
    local remaining_seconds=0
    local remaining_days=0
    local certificate_status=0

    if [[ $# -lt 1 || $# -gt 2 || -z $domain || ! $port =~ ^[0-9]+$ ]] \
        || (( port < 1 || port > 65535 )); then
        printf 'Usage: ssl-expiry <domain> [port (1-65535)]\n' >&2
        return 2
    fi

    if ! command -v openssl >/dev/null 2>&1; then
        printf 'ssl-expiry: openssl is required\n' >&2
        return 127
    fi

    certificate=$(
        openssl s_client -connect "${domain}:${port}" -servername "$domain" \
            </dev/null 2>/dev/null
    )

    if [[ -z $certificate ]]; then
        printf 'ssl-expiry: unable to retrieve a certificate from %s:%s\n' \
            "$domain" "$port" >&2
        return 1
    fi

    details=$(
        printf '%s\n' "$certificate" \
            | openssl x509 -noout -subject -issuer -startdate -enddate 2>/dev/null
    ) || {
        printf 'ssl-expiry: invalid certificate response from %s:%s\n' \
            "$domain" "$port" >&2
        return 1
    }

    end_date=$(printf '%s\n' "$details" | sed -n 's/^notAfter=//p')
    now_epoch=$(date +%s)

    if end_epoch=$(date -j -f '%b %e %T %Y %Z' "$end_date" +%s 2>/dev/null); then
        :
    elif end_epoch=$(date -d "$end_date" +%s 2>/dev/null); then
        :
    else
        end_epoch=""
    fi

    printf 'Host: %s:%s\n' "$domain" "$port"
    printf '%s\n' "$details"

    if [[ -n $end_epoch ]]; then
        remaining_seconds=$((end_epoch - now_epoch))
        if (( remaining_seconds >= 0 )); then
            remaining_days=$(((remaining_seconds + 86399) / 86400))
            printf 'Remaining: %d day(s)\n' "$remaining_days"
        else
            remaining_days=$(((-remaining_seconds + 86399) / 86400))
            printf 'Expired: %d day(s) ago\n' "$remaining_days"
        fi
    else
        printf 'Remaining: unavailable (could not parse certificate date)\n'
    fi

    if printf '%s\n' "$certificate" \
        | openssl x509 -checkend 0 -noout >/dev/null 2>&1; then
        printf 'Status: valid\n'
    else
        printf 'Status: expired\n' >&2
        certificate_status=1
    fi

    return "$certificate_status"
}

# config-tools url-encode: URL-encode arguments or standard input
function url-encode()
{
    local input_text="$*"

    if command -v python3 >/dev/null 2>&1; then
        if [[ $# -gt 0 ]]; then
            python3 -c 'import sys, urllib.parse
print(urllib.parse.quote(sys.argv[1], safe="-._~"))' "$input_text"
        else
            python3 -c 'import sys, urllib.parse
print(urllib.parse.quote_from_bytes(sys.stdin.buffer.read(), safe="-._~"))'
        fi
        return $?
    fi

    if command -v jq >/dev/null 2>&1; then
        if [[ $# -gt 0 ]]; then
            printf '%s' "$input_text" | jq -sRr @uri
        else
            jq -sRr @uri
        fi
        return $?
    fi

    printf 'url-encode: install Python 3 or jq to encode URLs\n' >&2
    return 127
}

function _dns-info-query()
{
    local backend=$1
    local domain=$2
    local record_type=$3
    local output=""
    local query_result=0

    if [[ $backend == dig ]]; then
        output=$(dig +short "$domain" "$record_type" 2>&1) || query_result=$?
    else
        output=$(host -t "$record_type" "$domain" 2>&1) || query_result=$?
    fi

    printf '\n== %s ==\n' "$record_type"

    if [[ $query_result -ne 0 ]]; then
        printf 'Query failed: %s\n' "$output" >&2
        return 1
    fi

    if [[ -z $output ]]; then
        printf '(none)\n'
    else
        printf '%s\n' "$output"
    fi
}

# config-tools dns-info: Show common DNS records for a domain
function dns-info()
{
    local domain="${1:-}"
    local backend=""
    local record_type=""
    local query_status=0

    if [[ $# -ne 1 || -z $domain || $domain == -* ]]; then
        printf 'Usage: dns-info <domain>\n' >&2
        return 2
    fi

    if command -v dig >/dev/null 2>&1; then
        backend=dig
    elif command -v host >/dev/null 2>&1; then
        backend=host
    else
        printf 'dns-info: install dig or host to query DNS records\n' >&2
        return 127
    fi

    printf 'DNS records for %s\n' "$domain"
    for record_type in A AAAA MX NS TXT; do
        _dns-info-query "$backend" "$domain" "$record_type" || query_status=1
    done

    return "$query_status"
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
