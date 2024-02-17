
function symlink-create()
{
    target=$1
    symlink_target=$2
    ln -sf ${target} "${symlink_target}"
}
