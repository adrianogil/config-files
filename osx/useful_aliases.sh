# Do something under Mac OS X platform

# https://github.com/danyshaanan/osx-wifi-cli
alias wifi='osx-wifi-cli'

alias shuf='gshuf'
alias open-url='open'

alias ot='open -a Terminal'

function dmgs()
{
    if [[ $1 == "-d" ]]; then
        gfind . -name '*.dmg' -type f -printf "%-.22T+ %M %n %-8u %-8g %8s %Tx %.8TX %p\n" | sort -r | awk '{print $9"\t"$1}'
    else
        find . -name '*.dmg'
    fi
}

function osx-change-host-machine()
{
    host_name=$1

    sudo scutil --set HostName $host_name
}
