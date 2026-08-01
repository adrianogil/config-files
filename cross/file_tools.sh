
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

# config-tools rename: Rename or move a file/directory
function rename()
{
    local source_path=""
    local target_path=""

    if [[ $# -eq 2 ]]; then
        source_path=$1
        target_path=$2
    elif [[ $# -eq 0 ]]; then
        source_path=$(find . -mindepth 1 | default-fuzzy-finder) || return 1

        if [[ -z $source_path ]]; then
            return 1
        fi

        printf 'Rename %s to: ' "$source_path"
        IFS= read -r target_path
    else
        printf 'Usage: rename <source> <target>\n' >&2
        printf '       rename\n' >&2
        return 1
    fi

    if [[ -z $target_path ]]; then
        printf 'rename: missing target path\n' >&2
        return 1
    fi

    mv -- "$source_path" "$target_path"
}

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

# config-tools largest-files: List the largest files below a directory
function largest-files()
{
    local target_directory="${1:-.}"
    local count="${2:-20}"

    if [[ $# -gt 2 || ! $count =~ ^[1-9][0-9]*$ ]]; then
        printf 'Usage: largest-files [directory] [count]\n' >&2
        return 2
    fi

    if [[ ! -d $target_directory ]]; then
        printf 'largest-files: %s: Not a directory\n' "$target_directory" >&2
        return 1
    fi

    printf 'KiB\tFile\n'
    find "$target_directory" -type f -exec du -k {} + 2>/dev/null \
        | sort -nr \
        | head -n "$count"
}

function _checksum-select-method()
{
    local method=""

    method=$(
        printf 'sha256\nsha512\nsha1\nmd5\n' \
            | default-fuzzy-finder --prompt='checksum method> ' --height=40% --reverse
    ) || {
        printf 'checksum: method selection cancelled or unavailable\n' >&2
        return 1
    }

    [[ -n $method ]] || return 1
    printf '%s\n' "$method"
}

function _checksum-value()
{
    local target_file=$1
    local method=$2
    local value=""

    case "$method" in
        md5)
            if command -v md5sum >/dev/null 2>&1; then
                value=$(md5sum -- "$target_file" | awk '{print $1}')
            elif command -v md5 >/dev/null 2>&1; then
                value=$(md5 -q -- "$target_file")
            elif command -v openssl >/dev/null 2>&1; then
                value=$(openssl dgst -md5 "$target_file" | awk '{print $NF}')
            fi
            ;;
        sha1)
            if command -v sha1sum >/dev/null 2>&1; then
                value=$(sha1sum -- "$target_file" | awk '{print $1}')
            elif command -v shasum >/dev/null 2>&1; then
                value=$(shasum -a 1 -- "$target_file" | awk '{print $1}')
            elif command -v openssl >/dev/null 2>&1; then
                value=$(openssl dgst -sha1 "$target_file" | awk '{print $NF}')
            fi
            ;;
        sha256)
            if command -v sha256sum >/dev/null 2>&1; then
                value=$(sha256sum -- "$target_file" | awk '{print $1}')
            elif command -v shasum >/dev/null 2>&1; then
                value=$(shasum -a 256 -- "$target_file" | awk '{print $1}')
            elif command -v openssl >/dev/null 2>&1; then
                value=$(openssl dgst -sha256 "$target_file" | awk '{print $NF}')
            fi
            ;;
        sha512)
            if command -v sha512sum >/dev/null 2>&1; then
                value=$(sha512sum -- "$target_file" | awk '{print $1}')
            elif command -v shasum >/dev/null 2>&1; then
                value=$(shasum -a 512 -- "$target_file" | awk '{print $1}')
            elif command -v openssl >/dev/null 2>&1; then
                value=$(openssl dgst -sha512 "$target_file" | awk '{print $NF}')
            fi
            ;;
    esac

    if [[ -z $value ]]; then
        printf 'checksum: no %s implementation is available\n' "$method" >&2
        return 127
    fi

    printf '%s\n' "$value"
}

# config-tools checksum: Generate a checksum for a file
function checksum()
{
    local target_file="${1:-}"
    local method="${2:-}"
    local value=""

    if [[ $# -lt 1 || $# -gt 2 ]]; then
        printf 'Usage: checksum <file> [sha256|sha512|sha1|md5]\n' >&2
        return 2
    fi

    if [[ ! -r $target_file || ! -f $target_file ]]; then
        printf 'checksum: %s: No such readable file\n' "$target_file" >&2
        return 1
    fi

    if [[ -z $method ]]; then
        method=$(_checksum-select-method) || return 1
    fi

    case "$method" in
        md5|MD5) method=md5 ;;
        sha1|SHA1|sha-1|SHA-1) method=sha1 ;;
        sha256|SHA256|sha-256|SHA-256) method=sha256 ;;
        sha512|SHA512|sha-512|SHA-512) method=sha512 ;;
        *)
            printf 'checksum: unsupported method: %s\n' "$method" >&2
            return 2
            ;;
    esac

    value=$(_checksum-value "$target_file" "$method") || return $?
    printf '%s  %s\n' "$value" "$target_file"
}

# config-tools checksum-verify: Verify a file against an expected checksum
function checksum-verify()
{
    local target_file="${1:-}"
    local expected="${2:-}"
    local method="${3:-}"
    local expected_length=0
    local actual=""

    if [[ $# -lt 2 || $# -gt 3 ]]; then
        printf 'Usage: checksum-verify <file> <hash> [sha256|sha512|sha1|md5]\n' >&2
        return 2
    fi

    if [[ ! -r $target_file || ! -f $target_file ]]; then
        printf 'checksum-verify: %s: No such readable file\n' "$target_file" >&2
        return 1
    fi

    if [[ -z $method ]]; then
        method=$(_checksum-select-method) || return 1
    fi

    case "$method" in
        md5|MD5)
            method=md5
            expected_length=32
            ;;
        sha1|SHA1|sha-1|SHA-1)
            method=sha1
            expected_length=40
            ;;
        sha256|SHA256|sha-256|SHA-256)
            method=sha256
            expected_length=64
            ;;
        sha512|SHA512|sha-512|SHA-512)
            method=sha512
            expected_length=128
            ;;
        *)
            printf 'checksum-verify: unsupported method: %s\n' "$method" >&2
            return 2
            ;;
    esac

    if [[ ! $expected =~ ^[0-9a-fA-F]+$ ]] || (( ${#expected} != expected_length )); then
        printf 'checksum-verify: expected a %d-character hexadecimal %s hash\n' \
            "$expected_length" "$method" >&2
        return 2
    fi

    expected=$(printf '%s' "$expected" | tr '[:upper:]' '[:lower:]')
    actual=$(_checksum-value "$target_file" "$method") || return $?

    if [[ $actual != "$expected" ]]; then
        printf 'FAIL: %s checksum does not match for %s\n' "$method" "$target_file" >&2
        printf 'Expected: %s\nActual:   %s\n' "$expected" "$actual" >&2
        return 1
    fi

    printf 'OK: %s checksum matches for %s\n' "$method" "$target_file"
}

# config-tools disk-free: Show available disk space and warn when it is low
function disk-free()
{
    local target_path="${1:-.}"
    local warning_threshold="${DISK_FREE_WARN_PERCENT:-10}"
    local df_output=""
    local filesystem=""
    local available_kib=0
    local used_percent=0
    local free_percent=0
    local mounted_on=""
    local available_human=""

    if [[ $# -gt 1 ]]; then
        printf 'Usage: disk-free [path]\n' >&2
        return 2
    fi

    if [[ ! -e $target_path ]]; then
        printf 'disk-free: %s: No such file or directory\n' "$target_path" >&2
        return 1
    fi

    if [[ ! $warning_threshold =~ ^[1-9][0-9]*$ ]] \
        || (( warning_threshold > 99 )); then
        printf 'disk-free: DISK_FREE_WARN_PERCENT must be between 1 and 99\n' >&2
        return 2
    fi

    df_output=$(df -Pk "$target_path") || return 1
    filesystem=$(printf '%s\n' "$df_output" | awk 'NR == 2 {print $1}')
    available_kib=$(printf '%s\n' "$df_output" | awk 'NR == 2 {print $4}')
    used_percent=$(printf '%s\n' "$df_output" | awk 'NR == 2 {gsub(/%/, "", $5); print $5}')
    mounted_on=$(printf '%s\n' "$df_output" | awk 'NR == 2 {print $NF}')

    if [[ ! $available_kib =~ ^[0-9]+$ || ! $used_percent =~ ^[0-9]+$ ]]; then
        printf 'disk-free: unable to parse df output for %s\n' "$target_path" >&2
        return 1
    fi

    free_percent=$((100 - used_percent))
    available_human=$(
        awk -v kib="$available_kib" 'BEGIN {
            value = kib
            unit = "KiB"
            if (value >= 1024) { value /= 1024; unit = "MiB" }
            if (value >= 1024) { value /= 1024; unit = "GiB" }
            if (value >= 1024) { value /= 1024; unit = "TiB" }
            printf "%.1f %s", value, unit
        }'
    )

    printf 'Filesystem: %s\n' "$filesystem"
    printf 'Mounted on: %s\n' "$mounted_on"
    printf 'Available:  %s (%d%% free)\n' "$available_human" "$free_percent"

    if (( free_percent < warning_threshold )); then
        printf 'WARNING: free space is below %d%%.\n' "$warning_threshold" >&2
        return 1
    fi

    printf 'Status:     OK\n'
}


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

    if type dush >/dev/null 2>&1; then
        printf '\n== dush ==\n'
        dush -- "$target"
    fi

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

# config-tools file-navigate-fzf: Recursively navigate files/dirs with fzf, then copy selected file path or cd
function file-navigate-fzf() {
    local current_dir="${1:-.}"
    local selection=""
    local entries=""
    local abs_target=""
    local rel_target=""
    local name=""

    current_dir="${current_dir%/}"

    while true; do
        entries=$(
            find "$current_dir" -mindepth 1 -maxdepth 1 2>/dev/null \
                | while IFS= read -r path; do
                    name="${path#"$current_dir/"}"

                    if [[ -d "$path" ]]; then
                        printf '%s/\n' "$name"
                    else
                        printf '%s\n' "$name"
                    fi
                done \
                | sort
        )

        selection=$(
            printf './\n../\n%s\n' "$entries" |
                default-fuzzy-finder --prompt="${current_dir}/ > "
        ) || return 1

        if [[ -z "$selection" ]]; then
            return 1
        fi

        # "./" means: select current directory and cd into it
        if [[ "$selection" == "./" ]]; then
            cd "$current_dir" || return 1
            return 0
        fi

        if [[ "$selection" == "../" ]]; then
            current_dir=$(cd "$current_dir/.." 2>/dev/null && pwd -P) || return 1
            continue
        fi

        # Remove trailing "/" used only as a directory marker
        selection="${selection%/}"

        abs_target="$current_dir/$selection"

        if [[ -d "$abs_target" ]]; then
            current_dir="$abs_target"
            continue
        fi

        rel_target="${abs_target#./}"
        echo "$rel_target" | copy-text-to-clipboard
        printf 'Copied %s\n' "$rel_target"
        return 0
    done
}

alias navi-file="file-navigate-fzf"
alias z="file-navigate-fzf"

# config-tools code-file-navigate-fzf: Recursively navigate files/dirs with fzf, then open selected file/dir in VS Code
function code-file-navigate-fzf() {
    local current_dir="${1:-.}"
    local selection=""
    local entries=""
    local target_path=""
    local name=""

    current_dir="${current_dir%/}"

    while true; do
        entries=$(
            find "$current_dir" -mindepth 1 -maxdepth 1 2>/dev/null \
                | while IFS= read -r path; do
                    name="${path#"$current_dir/"}"

                    if [[ -d "$path" ]]; then
                        printf '%s/\n' "$name"
                    else
                        printf '%s\n' "$name"
                    fi
                done \
                | sort
        )

        selection=$(
            printf './\n%s\n' "$entries" |
                default-fuzzy-finder --prompt="code ${current_dir}/ > "
        ) || return 1

        if [[ -z "$selection" ]]; then
            return 1
        fi

        # "./" means: open the current directory in VS Code
        if [[ "$selection" == "./" ]]; then
            code "$current_dir"
            return $?
        fi

        # Remove trailing "/" used only as a directory marker
        selection="${selection%/}"

        target_path="$current_dir/$selection"

        # If target is a directory, enter it and continue navigating
        if [[ -d "$target_path" ]]; then
            current_dir="$target_path"
            continue
        fi

        # If target is a file, open it in VS Code
        printf '%s\n' "${target_path#./}"
        code "$target_path"
        return $?
    done
}

alias code-navi-file="code-file-navigate-fzf"
alias cndz="code-file-navigate-fzf"
