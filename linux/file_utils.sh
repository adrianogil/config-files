
alias open="xdg-open"

function o()
{
    target_file=$1
    open $target_file
}

function gen-file()
{
    local size=$1
    local filename=$2

    fallocate -l $size $filename
}
