function f
{
    if [ -z "$2" ]
    then
        target_directory='.'
    else
        target_directory=$2
    fi

    echo "Trying to search "$1" in directory "$target_directory
    echo ""

    find $target_directory -name "$1"
}

alias md='mkdir'
alias mp='mkdir -p'

function cd_up() {
  cd $(printf "%0.s../" $(seq 1 $1 ));
}
alias 'cd..'='cd_up'