# Generate a random number from 0 to 999999
alias rndnumber='echo $(( ( RANDOM % 1000 * 1000 + RANDOM % 1000) ))'

alias pwdcp='pwd | pbcopy'

function weather()
{
    finger $(echo $1 | tr '[:upper:]' '[:lower:]')@graph.no
}

function serverssh()
{
    if [ -z "$1" ]
    then
        ssh_port=7375
    else
        ssh_port=$1
    fi
    echo "Starting sshd server using port "$ssh_port
    sshd -p $ssh_port
}

# Function to find files in a directory
function f
{
    if [ -z "$1" ]
    then
        echo 'usage: f <search_string> <path>'
    else
        if [ "$1" == "-v" ]; then
            if [ -z "$3" ]
            then
                target_directory='.'
            else
                target_directory=$3
            fi

            echo "Trying to search "$2" in directory "$target_directory
            echo ""

            find $target_directory -name "$2"
        else
            if [ -z "$2" ]
            then
                target_directory='.'
            else
                target_directory=$2
            fi

            find $target_directory -name "$1"
        fi
    fi
}

function fcount
{
    if [ -z "$1" ]
    then
        echo 'usage: f <search_string> <path>'
    else
        if [ "$1" == "-v" ]; then
            if [ -z "$3" ]
            then
                target_directory='.'
            else
                target_directory=$3
            fi

            echo "Trying to search "$2" in directory "$target_directory
            echo ""

            find $target_directory -name "$2" | wc -l
        else
            if [ -z "$2" ]
            then
                target_directory='.'
            else
                target_directory=$2
            fi

            find $target_directory -name "$1" | wc -l
        fi
    fi
}

# Directory creation
function md()
{
    echo 'Creating directory '$1
    mkdir $1
}

function mdd()
{
    echo 'Creating directory '$1
    mkdir $1
    echo 'Entrying directory '$1
    cd $1
}

alias mp='mkdir -p'

function cd_up() {
  cd $(printf "%0.s../" $(seq 1 $1 ));
}
alias 'cd..'='cd_up'

alias p2='python2'
alias p3='python3'

alias xa='xargs -I {}'

# sudo ln -s /System/Library/PrivateFrameworks/Apple80211.framework/Versions/Current/Resources/airport /usr/local/bin/airport
alias lwifi-list='airport -s'
alias lwifi-saved-list='defaults read /Library/Preferences/SystemConfiguration/com.apple.airport.preferences |grep SSIDString'

function searchtext()
{
    # Search text using grep
    # You can also use: pt String -G .extension
    if [ -z "$2" ]
    then
        target_directory='.'
    else
        target_directory=$2
    fi

    if [ -z "$3" ]
    then
        grep -Rrnw $target_directory -e $1 --include=\*
    else
        grep -Rrnw $target_directory -e $1 --include=$3
    fi
}

function sha1()
{
    echo -n $1 | openssl sha1 | cut -c10-
}

# Count files by types
function ltypes
{
    if [ -z "$1" ]
    then
        target_directory='.'
    else
        target_directory=$1
    fi

    ls -p $target_directory | grep -v / | awk -F . '{print $NF}' | sort | uniq -c | awk '{print $2,$1}'
}

function cats
{
    cat $1 | less
}

function ss
{
    if [ -z "$1" ]
    then
        screen_name=$(basename $PWD)
    else
        screen_name=$1
    fi

    screen_name=$(echo $screen_name | tr '[:upper:]' '[:lower:]')

    screen -S $screen_name
}

alias sl='screen -list'
alias sr='screen -r'

alias youtube-dl-mp3='youtube-dl -x --audio-format "mp3" '

function youtube-dl-mp3-from-playlist()
{
    youtube-dl -j --flat-playlist $1 | jq -r '.id' | sed 's_^_https://youtube.com/v/_' | cut -c9- | xa youtube-dl  -x --audio-format "mp3" {}
}

function ffmpeg-m4a-to-mp3()
{
    # Based on this post: https://gist.github.com/christofluethi/646ae60d797a46a706a5
    ffmpeg $1.mp3 -i $1.m4a -codec:a libmp3lame -qscale:a 1
}

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

# https://www.omgubuntu.co.uk/2016/08/learn-new-word-terminal
alias vc="$HOME/.vocab"

alias reload_mes_configs='source ~/.bashrc'