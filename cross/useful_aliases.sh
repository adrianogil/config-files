
alias reload_mes_configs='source ~/.bashrc'
alias rl='reload_mes_configs'

function default-fuzzy-finder()
{
    fzf "$@"
}
alias fz='fzf'

# config-tools pick-copy: Pick a file using fzf and copy its path to clipboard
alias pick-copy='default-fuzzy-finder | copy-clipboard-function'

# config-tools cat-fz: Cat a file using fzf and read it using less
alias cat-fz='default-fuzzy-finder | xargs cat | less'
alias ctz='cat-fz'

# config-tools vim-fz: Open a file using fzf and edit it using vim
alias vim-fz='default-fuzzy-finder | xargs vim'
alias vz='vim-fz'

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

get-user-confirmation() {
  if [ -n "$ZSH_VERSION" ]; then
    read -k1 "ans?$1"; echo; printf '%s' "$ans"
  else
    read -r -n1 -p "$1" ans; echo; printf '%s' "$ans"
  fi
}


# config-tools shfz: Find an shell using find and fzf and run it
function shfz()
{
    target_file=$(find . -type f -name "*.sh" | default-fuzzy-finder)
    echo "Running ${target_file}"
    bash $target_file
}

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

# config-tools extract: Extract a supported archive into a directory
function extract()
{
    local archive="${1:-}"
    local destination="${2:-.}"
    local command_name=""
    local output_name=""

    if [[ -z $archive || $# -gt 2 ]]; then
        printf 'Usage: extract <archive> [destination]\n' >&2
        return 2
    fi

    if [[ ! -f $archive ]]; then
        printf 'extract: %s: No such archive\n' "$archive" >&2
        return 1
    fi

    case "$archive" in
        *.tar.bz2|*.tbz2) command_name=tar ;;
        *.tar.gz|*.tgz) command_name=tar ;;
        *.tar.xz|*.txz) command_name=tar ;;
        *.tar) command_name=tar ;;
        *.zip) command_name=unzip ;;
        *.rar) command_name=unrar ;;
        *.7z) command_name=7z ;;
        *.bz2) command_name=bzip2 ;;
        *.gz) command_name=gzip ;;
        *.xz) command_name=xz ;;
        *.Z) command_name=uncompress ;;
        *)
            printf 'extract: unsupported archive format: %s\n' "$archive" >&2
            return 2
            ;;
    esac

    if ! command -v "$command_name" >/dev/null 2>&1; then
        printf 'extract: %s is required to extract %s\n' "$command_name" "$archive" >&2
        return 127
    fi

    mkdir -p -- "$destination" || return 1

    case "$archive" in
        *.tar.bz2|*.tbz2) tar -xjf "$archive" -C "$destination" ;;
        *.tar.gz|*.tgz) tar -xzf "$archive" -C "$destination" ;;
        *.tar.xz|*.txz) tar -xJf "$archive" -C "$destination" ;;
        *.tar) tar -xf "$archive" -C "$destination" ;;
        *.zip) unzip "$archive" -d "$destination" ;;
        *.rar) unrar x "$archive" "$destination/" ;;
        *.7z) 7z x "$archive" "-o$destination" ;;
        *.bz2)
            output_name=$(basename -- "${archive%.bz2}")
            bzip2 -dc -- "$archive" > "$destination/$output_name"
            ;;
        *.gz)
            output_name=$(basename -- "${archive%.gz}")
            gzip -dc -- "$archive" > "$destination/$output_name"
            ;;
        *.xz)
            output_name=$(basename -- "${archive%.xz}")
            xz -dc -- "$archive" > "$destination/$output_name"
            ;;
        *.Z)
            output_name=$(basename -- "${archive%.Z}")
            uncompress -c -- "$archive" > "$destination/$output_name"
            ;;
    esac
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

function tree-du()
{
    tree --du -shaC
}
