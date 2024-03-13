
################################################################################
# Using TMUX
function tnew()
{
    if [ -z "$1" ]
    then
        windows_name=$(basename $PWD)
    else
        windows_name=$1
    fi

    # determine the user's current position relative tmux:
    # serverless - there is no running tmux server
    # attached   - the user is currently attached to the running tmux server
    # detached   - the user is currently not attached to the running tmux server
    T_RUNTYPE="serverless"
    if [ "$TMUX_RUNNING" -eq 0 ]; then
        if [ "$TMUX" ]; then # inside tmux
            T_RUNTYPE="attached"
        else # outside tmux
            T_RUNTYPE="detached"
        fi
    fi

    if [ -z "$2" ]
    then
        # if attached, create a new session and then switch to it
        if [ "$T_RUNTYPE" = "attached" ]; then
            tmux new -d -s $windows_name
            tmux switch-client -t $windows_name
        else
            tmux new -s $windows_name
        fi
    else
        target_directory=$2
        # if attached, create a new session and then switch to it
        if [ "$T_RUNTYPE" = "attached" ]; then
            tmux new -d -s $windows_name -c $target_directory
            tmux switch-client -t $windows_name
        else
            tmux new -s $windows_name -c $target_directory
        fi
    fi
}
alias tn="tnew"

function tnew-basic-sessions()
{
    # Create sessions I usually start

    tmux new-session -d -s "home" -c $HOME/
    tmux new-session -d -s "notes" -c $HOME/Notes/
    tmux new-session -d -s "gdev" -c $HOME/workspace/
}

function tlist()
{
    tmux ls
}
alias tl="tlist"

function tenter()
{
    windows_name=$1

    # determine the user's current position relative tmux:
    # serverless - there is no running tmux server
    # attached   - the user is currently attached to the running tmux server
    # detached   - the user is currently not attached to the running tmux server
    T_RUNTYPE="serverless"
    if [ "$TMUX_RUNNING" -eq 0 ]; then
        if [ "$TMUX" ]; then # inside tmux
            T_RUNTYPE="attached"
        else # outside tmux
            T_RUNTYPE="detached"
        fi
    fi

    # if attached, create a new session and then switch to it
    if [ "$T_RUNTYPE" = "attached" ]; then
        tmux switch-client -t $windows_name
    else
        tmux attach -t $windows_name
    fi
}
alias te="tenter"

alias tw="tmux list-windows -a"

function t()
{
    _current_screen_list=$(tlist | sed 's/:/ /g' | awk '{print $1}')

    if [ -z "$1" ]
    then
        tlist
    elif [[ $_current_screen_list == *"$1"* ]];
    then
        echo "Let's open existing screen"
        tenter $1
    else
        echo "Let's create a new screen"
        tnew $1
    fi
}

function tfz()
{
    target_screen=$(tlist | default-fuzzy-finder | sed 's/:/ /g' | awk '{print $1}')
    t ${target_screen}
}

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
if [ -x "$BASH" ] && shopt -q >/dev/null 2>&1; then                # bash
    complete -F _tenter tenter
    complete -F _tenter te
    complete -F _tenter t
fi

alias treload-conf="tmux source-file ~/.tmux.conf"

# TODO
# Study code from https://gist.githubusercontent.com/ttscoff/a37427a8c331f072904d/raw/968192d7d0aabcde280155d0872dfa8cd8270619/tmux.bash

################################################################################
# Using Screen

function sname()
{
    echo "Current screen is called: "$STY
}

function ss()
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

function squit()
{
    # Screen Kill

    target_session=$(screen -list | grep $1 | awk '{print $1}' | head -1)

    screen -X -S ${target_session} quit

    echo "session "${target_session}" was killed!"
}

function open_screen()
{
    if [ -z "$1" ]
    then
        screen_name=$(sl | grep "(Detached)" | rev | cut -c12- | rev | awk '{print $1}' | default-fuzzy-finder)
    else
        screen_name=$1
    fi

    screen -r ${screen_name}
}
alias sr='open_screen'

alias sl='screen -list'
alias swipe='screen -wipe'
