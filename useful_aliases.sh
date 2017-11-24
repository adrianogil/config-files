function f
{
    if [ -z "$2" ]
    then
        target_directory='.'
    else
        target_directory=$2
    fi

    echo "Trying to search "$1" in directory "$target_directory 
    echo ""

    find $target_directory -name "$1"
}