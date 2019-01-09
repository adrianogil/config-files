function open-url()
{
    url=$1
    adb shell am start -a "android.intent.action.VIEW" -d $url
}


# @tool open-chrome-session Open URLs from a chrome session file
# Using https://github.com/prasmussen/chrome-cli
function open-chrome-session()
{
    if [ -z "$1" ]
    then
        session_file=$(gfind . -name '*.chrome-session' -type f -printf "%-.22T+ %M %n %-8u %-8g %8s %Tx %.8TX %p\n" | sort -r | awk '{print $9}' | head -1)
    else
        session_file=$1
    fi
    echo 'Loading chrome session file: '$session_file
    session_size=$(cat $session_file | wc -l)
    echo 'Trying to open session with '$session_size' saved tabs'
    cat $session_file | xargs -I {} open-url {}
}
