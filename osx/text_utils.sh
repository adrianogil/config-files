function sublimeb
{
    # Send text content to Sublime buffer
    sublime --command 'insert_snippet {"contents" : "'$1'"}'
}

alias s="sublime"
alias sw="sublime -n"

function sg()
{
    # Open new file into sublime and add it to git
    new_file=$1
    touch ${new_file}
    git add ${new_file}
    sublime ${new_file}
}

function tg()
{
    # Create new file and add it to git
    new_file=$1
    touch ${new_file}
    git add ${new_file}
}
