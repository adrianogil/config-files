alias o="open"

# config-tools ds_store: list .DS_Store files
function ds_store()
{
    find . -name ".DS_Store"
}

# config-tools ds_store-rm: remove .DS_Store files
function ds_store-rm()
{
    find . -name ".DS_Store" -exec rm -f {} \;
}

function gen-file()
{
    local size=$1
    local filename=$2

    mkfile $size $filename
}
