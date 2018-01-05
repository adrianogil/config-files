alias pwdcp='pwd | pbcopy'

# Function to find files in a directory
function f
{
    if [ -z "$1" ]
    then
        echo 'usage: f <search_string> <path>'
    else
        if [ "$1" == "-v" ]; then
            if [ -z "$3" ]
            then
                target_directory='.'
            else
                target_directory=$3
            fi

            echo "Trying to search "$2" in directory "$target_directory
            echo ""

            find $target_directory -name "$2"
        else
            if [ -z "$2" ]
            then
                target_directory='.'
            else
                target_directory=$2
            fi

            find $target_directory -name "$1"
        fi
    fi
}

# Directory creation
function md()
{
    echo 'Creating directory '$1
    mkdir $1
}

alias mp='mkdir -p'

function cd_up() {
  cd $(printf "%0.s../" $(seq 1 $1 ));
}
alias 'cd..'='cd_up'

alias reload_mes_configs='source ~/.profile'