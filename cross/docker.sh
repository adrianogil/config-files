
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
