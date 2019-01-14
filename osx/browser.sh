# @tool count-chrome-tabs Count current open tabs on chrome
# Using https://github.com/prasmussen/chrome-cli
function count-chrome-tabs()
{
    echo $(chrome-cli list links | wc -l)" open tabs in Chrome"
}

# @tool save-chrome-session Save chrome session into a file
# Using https://github.com/prasmussen/chrome-cli
function save-chrome-session()
{
    if [ -z "$1" ]
    then
        session_file='chrome_session_'$(date +%Y_%m_%d_%H_%M)'.chrome-session'
    else
        session_file=$1
    fi
    chrome-cli list links | awk '{print $2}' > $session_file
    session_size=$(cat $session_file | wc -l)
    echo 'Saved'$session_size' open tabs from Google Chrome into file '$session_file
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
    cat $session_file | xargs -I {} chrome-cli open {}
}

# @tool open-chrome-session Open URLs from a chrome session file
# Using https://github.com/prasmussen/chrome-cli
function open-chrome-session-droid()
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
    for u in `cat $session_file`; do echo "$u"; droid-open-url "$u"; sleep 1; done
}


function browser-current-window()
{
    current_tab=$(chrome-cli info | head -1 | awk '{print $2}')
    current_window=$(chrome-cli list tabs | grep $current_tab | tr ':[' ' ' | awk '{print $1}')
    chrome-cli list tabs -w $current_window
}

function browser-current-window-save-session()
{
    if [ -z "$1" ]
    then
        session_file=$(gfind . -name '*.chrome-session' -type f -printf "%-.22T+ %M %n %-8u %-8g %8s %Tx %.8TX %p\n" | sort -r | awk '{print $9}' | head -1)
    else
        session_file=$1'.chrome-session'
    fi

    current_tab=$(chrome-cli info | head -1 | awk '{print $2}')
    current_window=$(chrome-cli list tabs | grep $current_tab | tr ':[' ' ' | awk '{print $1}')
    chrome-cli list links -w $current_window | awk '{print $2}' > $session_file
    session_size=$(cat $session_file | wc -l)
    echo 'Saved'$session_size' open tabs from Google Chrome into file '$session_file
}

# @tool open-chrome-session Open URLs from a chrome session file
# Using https://github.com/prasmussen/chrome-cli
function browser-open-session()
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
    new_tab=$(for u in `cat $session_file | head -1`; do chrome-cli open $u -n; done | head -1 | awk '{print $2}')
    new_window=$(chrome-cli list tabs | grep $new_tab | tr ':[' ' ' | awk '{print $1}')

    for u in `cat $session_file | tail -n +2`;
    do 
        chrome-cli open $u -w $new_window;
    done
}

function browser-sessions()
{
    gfind . -name '*.chrome-session' -type f -printf "%-.22T+ %M %n %-8u %-8g %8s %Tx %.8TX %p\n" | sort -r | awk '{print $9}'
}

alias browser-open-session-sk='browser-open-session $(find . -name "*.chrome-session" | sk)'