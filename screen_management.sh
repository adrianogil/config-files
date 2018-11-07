
################################################################################
# Using TMUX
function tnew()
{
    windows_name=$1
    tmux new -s $windows_name
}
alias tn="tnew"

function tlist()
{
    tmux ls
}
alias tl="tlist"

function tenter()
{
    windows_name=$1
    tmux attach -t $windows_name
}
alias te="tenter"

_tenter()
{
    local cur prev opts
    COMPREPLY=()
    cur="${COMP_WORDS[COMP_CWORD]}"
    prev="${COMP_WORDS[COMP_CWORD-1]}"
    _current_windows=$(tlist | sed 's/:/ /g' | awk '{print $1}')
    COMPREPLY=( $(compgen -W "${_current_windows}" -- ${cur}) )
    return 0
}
complete -F _tenter tenter
complete -F _tenter te

################################################################################
# Using Screen

function sname()
{
    echo "Current screen is called: "$STY
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