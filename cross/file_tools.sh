
function symlink-create()
{
    target=$1
    symlink_target=$2
    ln -sf ${target} "${symlink_target}"
}

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

