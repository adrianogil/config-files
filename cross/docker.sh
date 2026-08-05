
function _docker-select-image()
{
    local images
    local selection

    images=$(
        docker images --format '{{.Repository}}:{{.Tag}}' |
            awk '$1 !~ /^<none>:<none>$/ && $1 !~ /^<none>:/ && $1 !~ /:<none>$/' |
            sort -u
    ) || return 1

    if [ -z "${images}" ]
    then
        printf 'No tagged local Docker images found.\n' >&2
        return 1
    fi

    selection=$(
        printf '%s\n' "${images}" |
            default-fuzzy-finder \
                --prompt='docker image> ' --height=40% --reverse
    ) || return 1

    [ -n "${selection}" ] || return 1
    printf '%s\n' "${selection}"
}

function _docker-container-rows()
{
    local scope=$1
    local format='{{.ID}}\t{{.Names}}\t{{.Image}}\t{{.Status}}'

    case "$scope" in
        running) docker ps --format "$format" ;;
        all) docker ps --all --format "$format" ;;
        stopped)
            docker ps --all \
                --filter status=created \
                --filter status=exited \
                --filter status=dead \
                --format "$format"
            ;;
        *)
            printf '_docker-container-rows: unknown scope: %s\n' "$scope" >&2
            return 2
            ;;
    esac
}

function _docker-select-containers()
{
    local scope=$1
    local prompt=$2
    local allow_multiple=$3
    local containers
    local selection

    containers=$(_docker-container-rows "$scope") || return 1
    if [ -z "$containers" ]
    then
        printf 'No %s Docker containers found.\n' "$scope" >&2
        return 1
    fi

    if [ "$allow_multiple" = yes ]
    then
        selection=$(
            printf '%s\n' "$containers" |
                default-fuzzy-finder \
                    --multi --prompt="$prompt" \
                    --header='ID  NAME  IMAGE  STATUS' \
                    --height=60% --reverse
        ) || return 1
    else
        selection=$(
            printf '%s\n' "$containers" |
                default-fuzzy-finder \
                    --prompt="$prompt" \
                    --header='ID  NAME  IMAGE  STATUS' \
                    --height=60% --reverse
        ) || return 1
    fi

    [ -n "$selection" ] || return 1
    printf '%s\n' "$selection" | awk -F '\t' '{ print $1 }'
}

# config-tools df-inspect-using-bash: Open a shell in a Docker image
function df-inspect-using-bash()
{
    local target_image="${1:-}"

    if [ "$#" -gt 1 ]
    then
        printf 'Usage: df-inspect-using-bash [image]\n' >&2
        return 2
    fi

    if [ -z "${target_image}" ]
    then
        target_image=$(_docker-select-image) || return 1
    fi

    docker run -it --entrypoint /bin/sh "${target_image}"
}

# config-tools docker-run-fzf: Run a Docker image selected via fzf
function docker-run-fzf()
{
    local docker_image

    docker_image=$(_docker-select-image) || return 1
    printf 'Running: docker run -it --rm %s\n' "${docker_image}" >&2
    docker run -it --rm "${docker_image}"
}

# config-tools docker-ps: Select and describe a running Docker container
function docker-ps()
{
    local container="${1:-}"

    if [ "$#" -gt 1 ]
    then
        printf 'Usage: docker-ps [container]\n' >&2
        return 2
    fi

    if [ -n "$container" ]
    then
        container=$(docker inspect --format '{{.Id}}' "$container") || return 1
    else
        container=$(_docker-select-containers running 'docker ps> ' no) || return 1
    fi

    docker ps --no-trunc --filter "id=$container" \
        --format 'table {{.ID}}\t{{.Names}}\t{{.Image}}\t{{.Status}}\t{{.Ports}}\t{{.Command}}'
}

# config-tools docker-stop: Select and stop running Docker containers
function docker-stop()
{
    local selection=""
    local container=""
    local containers=()

    if [ "$#" -gt 0 ]
    then
        containers=("$@")
    else
        selection=$(_docker-select-containers running 'docker stop> ' yes) || return 1
        while IFS= read -r container
        do
            [ -n "$container" ] && containers+=("$container")
        done <<< "$selection"
    fi

    [ "${#containers[@]}" -gt 0 ] || return 1
    docker stop "${containers[@]}"
}

# config-tools docker-start: Select and start stopped Docker containers
function docker-start()
{
    local selection=""
    local container=""
    local containers=()

    if [ "$#" -gt 0 ]
    then
        containers=("$@")
    else
        selection=$(_docker-select-containers stopped 'docker start> ' yes) || return 1
        while IFS= read -r container
        do
            [ -n "$container" ] && containers+=("$container")
        done <<< "$selection"
    fi

    [ "${#containers[@]}" -gt 0 ] || return 1
    docker start "${containers[@]}"
}

# config-tools docker-logs: Select a Docker container and follow its logs
function docker-logs()
{
    local container="${1:-}"
    local tail_lines="${DOCKER_LOG_TAIL:-100}"

    if [ "$#" -gt 1 ]
    then
        printf 'Usage: docker-logs [container]\n' >&2
        return 2
    fi
    if [[ ! $tail_lines =~ ^[1-9][0-9]*$ && $tail_lines != all ]]
    then
        printf 'docker-logs: DOCKER_LOG_TAIL must be a positive integer or all\n' >&2
        return 2
    fi

    if [ -z "$container" ]
    then
        container=$(_docker-select-containers all 'docker logs> ' no) || return 1
    fi

    docker logs --follow --tail "$tail_lines" "$container"
}

# config-tools docker-stats: Select and monitor running Docker containers
function docker-stats()
{
    local selection=""
    local container=""
    local containers=()

    if [ "$#" -gt 0 ]
    then
        containers=("$@")
    else
        selection=$(_docker-select-containers running 'docker stats> ' yes) || return 1
        while IFS= read -r container
        do
            [ -n "$container" ] && containers+=("$container")
        done <<< "$selection"
    fi

    [ "${#containers[@]}" -gt 0 ] || return 1
    docker stats "${containers[@]}"
}
