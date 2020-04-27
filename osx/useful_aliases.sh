# Do something under Mac OS X platform

# https://github.com/danyshaanan/osx-wifi-cli
alias wifi='osx-wifi-cli'

alias shuf='gshuf'
alias open-url='open'

alias ot='open -a Terminal'

# sudo ln -s /System/Library/PrivateFrameworks/Apple80211.framework/Versions/Current/Resources/airport /usr/local/bin/airport
alias lwifi-list='airport -s'
alias lwifi-saved-list='defaults read /Library/Preferences/SystemConfiguration/com.apple.airport.preferences |grep SSIDString'

function verify-host-accessible()
{
    TARGET_HOST=$1
    while ! ping -c1 ${TARGET_HOST} &>/dev/null; do
        echo "Ping Fail - `date`";
        sleep 60
    done ;
    terminal-notifier -title "Terminal" -message "${TARGET_HOST} is already accessible";
}

function dmgs()
{
    if [[ $1 == "-d" ]]; then
        gfind . -name '*.dmg' -type f -printf "%-.22T+ %M %n %-8u %-8g %8s %Tx %.8TX %p\n" | sort -r | awk '{print $9"\t"$1}'
    else
        find . -name '*.dmg'
    fi
}

function pdfs()
{
    if [[ $1 == "-d" ]]; then
        gfind . -name '*.pdf' -type f -printf "%-.22T+ %M %n %-8u %-8g %8s %Tx %.8TX %p\n" | sort -r | awk '{print $9"\t"$1}'
    else
        find . -name '*.pdf'
    fi
}

function du-sort-size()
{
    du -sh -- * | sort -h
}

# https://derflounder.wordpress.com/2018/04/07/reclaiming-drive-space-by-thinning-apple-file-system-snapshot-backups/
function osx-force-space-cleanup()
{
    tmutil thinlocalsnapshots / 21474836480 4
}

function osx-change-host-machine()
{
    # https://apple.stackexchange.com/questions/287760/set-the-hostname-computer-name-for-macos
    host_name=$1

    sudo scutil --set HostName $host_name
    sudo scutil --set LocalHostName ${host_name}
    sudo scutil --set ComputerName ${host_name}
}

function osx-setup-screenshots-folder()
{
    if [ -z "$1" ]
    then
        target_screenshot_folder=$SSH_DEFAULT_PORT
    else
        target_screenshot_folder=$1
    fi

    defaults write com.apple.screencapture location $target_screenshot_folder && killall SystemUIServer
}
