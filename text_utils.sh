# Send text content to Sublime buffer
function sublimeb
{
    sublime --command 'insert_snippet {"contents" : "'$1'"}'
}

alias s="sublime"