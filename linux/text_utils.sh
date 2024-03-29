# Linux - text utils

alias c="code"
alias cw="code -n"

alias copy-text-to-clipboard="xclip -selection clipboard"
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
