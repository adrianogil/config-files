# Linux - text utils

alias c="code"
alias cw="code -n"

function _clipboard-system-set()
{
    xclip -selection clipboard
}

function _clipboard-system-image-get()
{
    local output_file=$1

    if [[ -n ${WAYLAND_DISPLAY:-} ]] && command -v wl-paste >/dev/null 2>&1
    then
        wl-paste --type image/png > "${output_file}"
        return $?
    fi

    if ! command -v xclip >/dev/null 2>&1
    then
        printf '_clipboard-system-image-get: xclip or wl-clipboard is required\n' >&2
        return 127
    fi

    xclip -selection clipboard -t image/png -o > "${output_file}"
}

alias paste-text-from-clipboard="xclip -selection clipboard -o"

function tg()
{
    # Create new file and add it to git
    new_file=$1

    file_directory=$(dirname ${new_file})
    mkdir -p ${file_directory}

    touch ${new_file}
    git add ${new_file}
}

function cg()
{
    # Open new file into vscode and add it to git
    new_file=$1

    tg ${new_file}
    code ${new_file}
}
