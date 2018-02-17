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

function mdd()
{
    echo 'Creating directory '$1
    mkdir $1
    echo 'Entrying directory '$1
    cd $1
}

alias mp='mkdir -p'

function cd_up() {
  cd $(printf "%0.s../" $(seq 1 $1 ));
}
alias 'cd..'='cd_up'

alias p2='python'
alias p3='python3'

alias xa='xargs -I {}'

# sudo ln -s /System/Library/PrivateFrameworks/Apple80211.framework/Versions/Current/Resources/airport /usr/local/bin/airport
alias lwifi-list='airport -s'
alias lwifi-saved-list='defaults read /Library/Preferences/SystemConfiguration/com.apple.airport.preferences |grep SSIDString'

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

alias reload_mes_configs='source ~/.profile'