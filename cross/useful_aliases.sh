
alias reload_mes_configs='source ~/.bashrc'

alias default-fuzzy-finder='fzf'

alias pick-copy='default-fuzzy-finder | copy-clipboard-function'

alias l="ls"

alias lss="less"

alias h1='head -1'
alias h2='head -2'
alias h3='head -3'
alias h4='head -4'
alias h5='head -5'
alias h6='head -6'
alias h7='head -7'
alias h8='head -8'
alias h9='head -9'
alias h10='head -10'

alias t1='tail -1'
alias t2='tail -2'
alias t3='tail -3'
alias t4='tail -4'
alias t5='tail -5'
alias t6='tail -6'
alias t7='tail -7'
alias t8='tail -8'
alias t9='tail -9'
alias t10='tail -10'


alias cx='chmod +x'

alias sf="screenfetch"
alias sp="speedtest-cli"

alias dush="du -sh"

alias awk1="awk '{print $1}'"
alias awk2="awk '{print $2}'"

# alias for getting date yearmonthdayhourminute
alias ymdhm="date +%Y%m%d%H%M"

function pwok()
{
    workon $(lsvirtualenv -b | default-fuzzy-finder)
}

function nyahcat()
{
    # Continous reading from file output
    target_file=$1
    tail -f -n +0 ${target_file}
}

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

# Generate a random number from 0 to 999999
alias rndnumber='echo $(( ( RANDOM % 1000 * 1000 + RANDOM % 1000) ))'

alias xa='xargs -I {}'

function monitor-istats()
{
    # gem install iStats
    while true; do clear; istats; sleep 1; done
}

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

    find ${target_directory} -type f | grep -o ".[^.]\+$" | sort | uniq -c

    # ls -p $target_directory | grep -v / | awk -F . '{print $NF}' | sort | uniq -c | awk '{print $2,$1}'
}

# config-tools llastmodified: Show last modified file
function llastmodified
{
    find . -type f -print0 | xargs -0 ls -tl
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

alias opk='o $(default-fuzzy-finder)'

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

function rnd-time-quote()
{
    o "https://literature-clock.jenevoldsen.com/"
}


# https://www.omgubuntu.co.uk/2016/08/learn-new-word-terminal
alias vc="$HOME/.vocab"

function trees()
{
    tree $* | less
}
