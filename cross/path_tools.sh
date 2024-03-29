
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

function path-show() {
    echo -e ${PATH//:/\\n}
}

function pwdcp()
{
    if [[ $0 == *termux* ]]; then
        pwd | termux-clipboard-set
    else
        pwd | copy-text-to-clipboard
    fi
}
