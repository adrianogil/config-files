
function abspath() {
    # generate absolute path from relative path
    # $1     : relative filename
    # return : absolute path
    if [ -d "$1" ]; then
        # dir
        (cd "$1"; pwd)
    elif [ -f "$1" ]; then
        # file
        if [[ $1 = /* ]]; then
            echo "$1"
        elif [[ $1 == */* ]]; then
            echo "$(cd "${1%/*}"; pwd)/${1##*/}"
        else
            echo "$(pwd)/$1"
        fi
    fi
}

function abspathcp()
{
    abspath $1 | pbcopy
}

if [[ $0 == *termux* ]]; then
    function fleditor-android()
    {
        real_file_path=$(abspath $1)
        real_file_path=$(echo $real_file_path | sed "s@data/data/com.termux/files/home/storage/shared@sdcard@g" )
        echo "Open file "$1"using DroidEdit Free"
        am start -n "com.aor.droidedit/.DroidEditFreeActivity" -d "file://"$real_file_path
    }
# else
#     echo ""
fi
