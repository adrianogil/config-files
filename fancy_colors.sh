# set variable identifying the chroot you work in (used in the prompt below)
if [ -z "${debian_chroot:-}" ] && [ -r /etc/debian_chroot ]; then
    debian_chroot=$(cat /etc/debian_chroot)
fi

TERM=screen-256color

# set a fancy prompt (non-color, unless we know we "want" color)
case "$TERM" in
    *-*color) color_prompt=yes;;
esac

# uncomment for a colored prompt, if the terminal has the capability; turned
# off by default to not distract the user: the focus in a terminal window
# should be on the output of commands, not on the prompt
#force_color_prompt=yes

if [ -n "$force_color_prompt" ]; then
    if [ -x /usr/bin/tput ] && tput setaf 1 >&/dev/null; then
	# We have color support; assume it's compliant with Ecma-48
	# (ISO/IEC-6429). (Lack of such support is extremely rare, and such
	# a case would tend to support setf rather than setaf.)
	color_prompt=yes
    else
	color_prompt=
    fi
fi




parse_git_branch() {
    branch_name=$(git branch 2> /dev/null | sed -e '/^[^*]/d' -e 's/* \(.*\)/\1/ ')
    if [[ "$branch_name" ]]; then
        # staged_number=$(git diff --cached --numstat | wc -l)
        # not_staged_number=$(git diff --numstat | wc -l)
        min_value=0
        # if [ "$staged_number" -gt "$min_value" ]; then
        #     echo '['$branch_name'#'$staged_number's'$not_staged_number'ns]'
        # elif [ "$not_staged_number" -gt "$min_value" ]; then
        #     echo '['$branch_name'#'$not_staged_number'ns]'
        # else
        echo '['$branch_name']'
        # fi
    fi
}


if [ "$color_prompt" = yes ]; then
    PS1='\[\033[0;37m\]\342\224\214${debian_chroot:+[$debian_chroot]}\342\224\200[$(if [[ ${EUID} == 0 ]]; then echo "\[\033[0;31m\]\h"; else echo "\[\033[0;33m\]\u\[\033[0;37m\]@\[\033[0;96m\]\h"; fi)\[\033[0;37m\]]\342\224\200[\[\033[0;32m\]\w\[\033[0;37m\]][\t]\n\[\033[0;37m\]\342\224\224\342\224\200\342\225\274 $(parse_git_branch "\342\224\200[%s]")\[\033[0m\]$ '
else
    PS1='${debian_chroot:+($debian_chroot)}\u@\h:\t\w\$ '
fi
unset color_prompt force_color_prompt

# If this is an xterm set the title to user@host:dir
case "$TERM" in
xterm*|rxvt*)
    PS1="\[\e]0;${debian_chroot:+($debian_chroot)}\u@\h: \w\a\]$PS1"
    ;;
*)
    ;;
esac

PS1="$PS1"'$([ -n "$TMUX" ] && tmux setenv TMUXPWD_$(tmux display -p "#D" | tr -d %) "$PWD")'

# enable color support of ls and also add handy aliases
if [ -x /usr/bin/dircolors ]; then
    test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"
    alias ls='ls --color=auto'
    #alias dir='dir --color=auto'
    #alias vdir='vdir --color=auto'

    alias grep='grep --color=auto'
    alias fgrep='fgrep --color=auto'
    alias egrep='egrep --color=auto'
fi