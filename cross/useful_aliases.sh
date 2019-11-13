
alias l="ls"

alias lss="less"

alias h1='head -1'
alias t1='tail -1'

alias cx='chmod +x'

alias sf="screenfetch"
alias sp="speedtest-cli"

alias dush="du -sh"

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

function rnd-port()
{
    # Based on https://unix.stackexchange.com/a/447763
    while
        port=$(shuf -n 1 -i 8000-65535)
        netstat -atun | grep -q "$port"
    do
        continue
    done

    echo "$port"
}

function url-serve()
{
    target_html=$1
    port=$(rnd-port)

    shttp-server $port
    echo "Serve HTML file on port "$port
    open-url http://localhost:$port/$target_html
}

alias ips-net='ifconfig | grep net'
function ips()
{
    ifconfig | grep -E "([0-9]{1,3}\.){3}[0-9]{1,3}" | grep -v 127.0.0.1 | awk '{ print $2 }' | cut -f2 -d: | head -n1
}

# Generate a random number from 0 to 999999
alias rndnumber='echo $(( ( RANDOM % 1000 * 1000 + RANDOM % 1000) ))'

function pwdcp()
{
    if [[ $0 == *termux* ]]; then
        pwd | termux-clipboard-set
    else
        pwd | pbcopy
    fi
}

function weather()
{
    finger $(echo $1 | tr '[:upper:]' '[:lower:]')@graph.no
}

SSH_DEFAULT_PORT=7375

alias ssh2moi='ssh -p $SSH_DEFAULT_PORT'

function serverssh()
{
    if [ -z "$1" ]
    then
        ssh_port=$SSH_DEFAULT_PORT
    else
        ssh_port=$1
    fi
    echo "Starting sshd server using port "$ssh_port" on IP: "$(ips)
    sshd -p $ssh_port
}

# Directory creation
function md()
{
    echo 'Creating directory '$1
    mkdir -p $1
}

function mdd()
{
    echo 'Creating directory '$1
    mkdir -p $1
    echo 'Entrying directory '$1
    cd $1
}

function mddate()
{
    target_directory=$(date +%Y%m%d%H%M)

    echo 'Creating directory '${target_directory}
    mkdir -p ${target_directory}
    echo 'Entrying directory '${target_directory}
    cd ${target_directory}
}

alias mp='mkdir -p'

function cd_up() {
  cd $(printf "%0.s../" $(seq 1 $1 ));
}
alias 'cd..'='cd_up'

# Enter a directory from sk
# sk  = https://github.com/lotabout/skim
function cdk()
{
    cd $(find . -type d -regex '\./[^.]*$' | sk)
}

# Enter a directory from sk
# sk  = https://github.com/lotabout/skim
function cdk-all()
{
    cd $(find . -type d | sk)
}


alias p2='python2'
alias p3='python3'

function p3m()
{
    module_path=$1
    target_module=$(echo ${module_path} | tr '/' '.')
    target_module=${target_module/.py/}
    echo "Running module "${target_module}
    shift
    python3 -m ${target_module} $@
}

alias pi='pip install'

alias xa='xargs -I {}'

# sudo ln -s /System/Library/PrivateFrameworks/Apple80211.framework/Versions/Current/Resources/airport /usr/local/bin/airport
alias lwifi-list='airport -s'
alias lwifi-saved-list='defaults read /Library/Preferences/SystemConfiguration/com.apple.airport.preferences |grep SSIDString'

### From https://github.com/joseluisq/awesome-bash-commands ###

# @tool rnd-number <size>
function rnd-number()
{
    od -vAn -N64 < /dev/urandom | tr '\n' ' ' | sed "s/ //g" | head -c $1
}

# @tool rnd-alphanumeric <size>
function rnd-alphanumeric()
{
    base64 /dev/urandom | tr -d '/+' | head -c $1 | xargs
}

function rnd-words()
{
    word_dict=$1

    if [ -z "$2" ]
    then
        column_repeat=1
    else
        column_repeat=$2
    fi

    if [ -z "$RND_WHILE_VELOCITY" ]
    then
        rnd_velocity=0.5
    else
        rnd_velocity=$RND_WHILE_VELOCITY
    fi

    if [[ $0 == *termux* ]]; then
        while true; do
            current_word=''
            for i in `seq 1 $column_repeat`; do
                current_word=$(shuf -n1 $word_dict)"\t $current_word"
            done
            echo -e $current_word
            sleep $rnd_velocity
        done
    else
        while true; do
            current_word=''
            for i in `seq 1 $column_repeat`; do
                current_word=$(gshuf -n1 $word_dict)"\t $current_word"
            done
            echo -e $current_word
            sleep $rnd_velocity
        done
    fi
}

function rnd-words-pt()
{
    rnd-words $WORDS_PT_FILE $1
}

function rnd-words-en()
{
    rnd-words $WORDS_EN_FILE $1
}

function rnd-words-jp()
{
    rnd-words $WORDS_JP_FILE $1
}

### From https://www.reddit.com/r/commandline/comments/9md3pp/a_very_useful_bashrc_file/ ###

# random-hexdump
alias rnd-hexdump="cat /dev/urandom | hexdump -C | grep 'ca fe'"

# Easy way to extract archives
extract () {
   if [ -f $1 ] ; then
       case $1 in
           *.tar.bz2)   tar xvjf $1;;
           *.tar.gz)    tar xvzf $1;;
           *.bz2)       bunzip2 $1 ;;
           *.rar)       unrar x $1 ;;
           *.gz)        gunzip $1  ;;
           *.tar)       tar xvf $1 ;;
           *.tbz2)      tar xvjf $1;;
           *.tgz)       tar xvzf $1;;
           *.zip)       unzip $1   ;;
           *.Z)         uncompress $1  ;;
           *.7z)        7z x $1;;
           *) echo "don't know how to extract '$1'..." ;;
       esac
   else
       echo "'$1' is not a valid file!"
   fi
}

############################################################################################

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

function lsort()
{
    if [ -z "$1" ]
    then
        target_name='*'
    else
        target_name=$1
    fi

    if [ -z "$2" ]
    then
        target_directory='.'
    else
        target_directory=$2
    fi

    gfind "$target_directory" -name "$target_name" -type f -printf "%-.22T+ %M %n %-8u %-8g %8s %Tx %.8TX %p\n" | sort -r | awk '{print $1"\t"$9}'
}

function o()
{
    file=$1

    if [[ $0 == *termux* ]]; then
        droid-open $1
    else
        open $1
    fi
}

alias opk='o $(sk)'

# Copy using pv (http://www.ivarch.com/programs/pv.shtml)
# For more info take a look at: http://www.catonmat.net/blog/unix-utilities-pipe-viewer/
function cpv
{
    pv $1 > $2
}

function cats
{
    cat $1 | less
}

function rnd-line()
{
    file=$1
    head -$((${RANDOM} % `wc -l < $file` + 1)) $file | tail -1
}


alias youtube-dl-mp3='youtube-dl -x --audio-format "mp3" '


function youtube-dl-mp3-from-playlist()
{
    youtube-dl -j --flat-playlist $1 | jq -r '.id' | sed 's_^_https://youtube.com/v/_' | cut -c9- | xa youtube-dl  -x --audio-format "mp3" {}
}

# Based on https://stackoverflow.com/questions/18444194/cutting-the-videos-based-on-start-and-end-time-using-ffmpeg
function video-cut()
{
    target_video=$1
    output_video=$2
    start_time=$3    # 00:00:03
    duration_time=$4 # 00:00:08
    ffmpeg -i $target_video -ss $start_time -t $duration_time -async 1 $output_video
}

# https://www.omgubuntu.co.uk/2016/08/learn-new-word-terminal
alias vc="$HOME/.vocab"

function trees()
{
    tree $* | less
}

function workspace()
{
    cd ${WORKSPACE_DIR}
}

alias reload_mes_configs='source ~/.bashrc'

function mysk()
{
    target_dir=$(mydirs -l | tr ':' ' ' | awk '{print $1}' | sk)
    mydirs -o $target_dir
}

alias plot-cmd="python ${CONFIG_FILES_DIR}/python/plottool/plot_command.py"
