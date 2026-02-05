


function df-inspect-using-bash()
{
    target_image=$1

    docker run -it --entrypoint /bin/sh ${target_image}
}

# config-tools docker-run-fzf: Run a Docker image selected via fzf
function docker-run-fzf()
{
    local selection DOCKER_IMAGE

    # List local images as "repo:tag" (skip <none>)
    selection="$(
        docker images --format '{{.Repository}}:{{.Tag}}' \
            | awk '$1 !~ /^<none>:<none>$/ && $1 !~ /^<none>:/ && $1 !~ /:<none>$/' \
            | sort -u \
            | default-fuzzy-finder --prompt='docker image> ' --height=40% --reverse
    )"

    # If user canceled
    [[ -z "$selection" ]] && return 1

    DOCKER_IMAGE="$selection"
    echo "Running: docker run -it --rm ${DOCKER_IMAGE}" >&2
    docker run -it --rm "${DOCKER_IMAGE}"
}
