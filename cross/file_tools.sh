
function symlink-create()
{
    target=$1
    symlink_target=$2
    ln -sf ${target} "${symlink_target}"
}

# config-tools files-organize: Organize files in a directory
function files-organize()
{
    python3 ${CONFIG_FILES_DIR}/python/clitools/files_organizer.py
}

function smart-cp()
{
    source_file=$1
    target_file=$2

    echo "Source file: "$source_file
    echo "Target file: "$target_file

    target_directory=$(dirname "$target_file")

    echo "Attempt to create directory: "$target_directory
    mkdir -p $target_directory

    cp "$source_file" "$target_file"
}
alias smcp="smart-cp"

# config-tools files-zip: Zip files with a search parameter
function files-zip() {
    local search_param=$1
    local zip_name=$2

    if [ -z "$search_param" ] || [ -z "$zip_name" ]; then
        echo "Usage: zip_files <search_parameter> <zip_file_name>"
        return 1
    fi

    find . -type f -name "$search_param" | zip "$zip_name" -@
}

# config-tools files-last-modified: Get the last modified file in current directory
function files-last-modified()
{
    ls -ctd ./* | head -1
}
alias lmod="files-last-modified"


# config-tools file-to-prompt: Copy file content to clipboard in a format suitable for prompt
function file-to-prompt() {
    local file="${1:-}"
    # If no arg, pick one interactively
    if [[ -z $file ]]; then
        file=$(find . -type f | default-fuzzy-finder) || return 1
    fi

    # Validate
    if [[ ! -r $file ]]; then
    printf 'file_to_prompt: %s: No such readable file\n' "$file" >&2
    return 1
    fi

    local filename=$file

    # Stream into clipboard, with safe quoting
    {
        printf '%s\n' '```'"$filename"
        cat "$file"
        printf '%s' '```'
    } | copy-text-to-clipboard
}
alias fto="file-to-prompt"

# config-tools dir-to-prompt: Copy directory file contents to clipboard in a format suitable for prompt
function dir-to-prompt() {
    local dir="${1:-}"
    # If no arg, pick one interactively
    if [[ -z $dir ]]; then
        dir=$(find . -type d | default-fuzzy-finder) || return 1
    fi

    # Validate
    if [[ ! -d $dir ]]; then
        printf 'dir-to-prompt: %s: Not a directory\n' "$dir" >&2
        return 1
    fi

    if [[ ! -r $dir ]]; then
        printf 'dir-to-prompt: %s: Not a readable directory\n' "$dir" >&2
        return 1
    fi

    {
        while IFS= read -r file; do
            printf '%s\n' '```'"$file"
            cat "$file"
            printf '%s\n' '```'
        done < <(find "$dir" -type f)
    } | copy-text-to-clipboard
}
alias dto="dir-to-prompt"

# config-tools file-info: Show detailed information about a file
function file-info() {
    local target="${1:-}"

    if [[ -z $target ]]; then
        printf 'Usage: file-info <path>\n' >&2
        return 1
    fi

    if [[ ! -e $target ]]; then
        printf 'file-info: %s: No such file or directory\n' "$target" >&2
        return 1
    fi

    printf '\n== Path ==\n%s\n' "$target"
    printf '\n== file ==\n'
    file -- "$target"

    printf '\n== ls -la ==\n'
    ls -la -- "$target"

    if command -v stat >/dev/null 2>&1; then
        printf '\n== stat ==\n'
        stat -- "$target" 2>/dev/null || stat "$target"
    fi

    local created_at=""
    local updated_at=""
    local epoch_created=""

    if stat --version >/dev/null 2>&1; then
        created_at=$(stat -c %w -- "$target" 2>/dev/null)
        updated_at=$(stat -c %y -- "$target" 2>/dev/null)
    else
        epoch_created=$(stat -f %B -- "$target" 2>/dev/null)
        if [[ -n $epoch_created && $epoch_created != 0 ]]; then
            if date -r 0 >/dev/null 2>&1; then
                created_at=$(date -r "$epoch_created" "+%Y-%m-%d %H:%M:%S %z")
            else
                created_at=$(date -d "@$epoch_created" "+%Y-%m-%d %H:%M:%S %z")
            fi
        fi
        updated_at=$(stat -f "%Sm" -t "%Y-%m-%d %H:%M:%S %z" -- "$target" 2>/dev/null)
    fi

    if [[ -z $created_at || $created_at == "-" ]]; then
        created_at="unavailable"
    fi

    if [[ -z $updated_at ]]; then
        updated_at="unavailable"
    fi

    printf '\n== timestamps ==\n'
    printf 'Created: %s\n' "$created_at"
    printf 'Updated: %s\n' "$updated_at"

    if command -v getfacl >/dev/null 2>&1; then
        printf '\n== ACLs ==\n'
        getfacl -p -- "$target"
    fi

    if command -v xattr >/dev/null 2>&1; then
        printf '\n== extended attributes ==\n'
        xattr -l -- "$target"
    fi

    if command -v lsattr >/dev/null 2>&1; then
        printf '\n== lsattr ==\n'
        lsattr -- "$target"
    fi

    if command -v sha256sum >/dev/null 2>&1; then
        printf '\n== sha256sum ==\n'
        sha256sum -- "$target"
    elif command -v shasum >/dev/null 2>&1; then
        printf '\n== shasum -a 256 ==\n'
        shasum -a 256 -- "$target"
    fi

    if command -v md5sum >/dev/null 2>&1; then
        printf '\n== md5sum ==\n'
        md5sum -- "$target"
    elif command -v md5 >/dev/null 2>&1; then
        printf '\n== md5 ==\n'
        md5 -- "$target"
    fi

    if command -v exiftool >/dev/null 2>&1; then
        printf '\n== exiftool ==\n'
        exiftool -- "$target"
    fi
}
alias finfo="file-info"
