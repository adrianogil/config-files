function sublimeb
{
    # Send text content to Sublime buffer
    sublime --command 'insert_snippet {"contents" : "'$1'"}'
}

alias c="code"
alias cw="code -n"

alias s="sublime"
alias sw="sublime -n"

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


function sg()
{
    # Open new file into sublime and add it to git
    new_file=$1

    tg ${new_file}
    sublime ${new_file}
}
