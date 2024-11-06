# Initialize an empty array to store visited directories
declare -a VISITED_DIRS=()

# Override `cd` command to save each visited directory
cd() {
    # Call the built-in `cd` command with the provided arguments
    builtin cd "$@" || return

    # Get the absolute path of the new directory
    local new_dir=$(pwd)

    # Check if VISITED_DIRS is not empty before checking the last element
    if [[ ${#VISITED_DIRS[@]} -eq 0 || "${VISITED_DIRS[-1]}" != "$new_dir" ]]; then
        # Add the new directory to the history array
        VISITED_DIRS+=("$new_dir")

        # Keep only the last 20 directories
        if (( ${#VISITED_DIRS[@]} > 20 )); then
            VISITED_DIRS=("${VISITED_DIRS[@]:1}")
        fi
    fi
}

# Define a function to list the last visited directories
list_last_visited_paths() {
    echo "Last visited directories in this session:"
    for ((i=${#VISITED_DIRS[@]}-1; i>=0; i--)); do
        echo "$(( ${#VISITED_DIRS[@]} - i )): ${VISITED_DIRS[i]}"
    done
}

# config-tools cdback: Fuzzy-search and enter a directory from cd stack
function cdback() {
    last_path=$(list_last_visited_paths | default-fuzzy-finder | awk '{$1=""; print substr($0,2)}')
    cd "${last_path}"
}

