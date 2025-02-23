
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

# config-tools files-last-modified: Get the last modified file in a directory
function files-last-modified()
{
    ls -ctd ./* | head -1
}
alias lmod="files-last-modified"
