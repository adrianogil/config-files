function droid-open-text()
{
    echo "Open text file "$1"using DroidEdit Free"

    if [[ $0 == *termux* ]]; then
        real_file_path=$(abspath $1)
        real_file_path=$(echo $real_file_path | sed "s@data/data/com.termux/files/home/storage/shared@sdcard@g" )

        am start -n "$TEXT_EDITOR_APP" -d "file://"$real_file_path
    else
        real_file_path=$1
        real_file_path=$(echo $real_file_path | sed "s@data/data/com.termux/files/home/storage/shared@sdcard@g" )

        adb shell am start -n "$TEXT_EDITOR_APP" -d "file://"$real_file_path
    fi
}

function droid-open-text-as-tmp()
{
    file=$1

    echo "Open text file "$file" in a tmp folder using DroidEdit Free"

    filename=$(basename -- "$file")
    file_dir="${file%$filename}"

    tmp_path=/sdcard/tmp/tmp_$filename

    cp $file $tmp_path

    echo $tmp_path > $file.tmp
    text_file=$tmp_path

    if [[ $0 == *termux* ]]; then
        real_file_path=$(abspath $text_file)
        real_file_path=$(echo $real_file_path | sed "s@data/data/com.termux/files/home/storage/shared@sdcard@g" )

        am start -n "$TEXT_EDITOR_APP" -d "file://"$real_file_path
    else
        real_file_path=$text_file
        real_file_path=$(echo $real_file_path | sed "s@data/data/com.termux/files/home/storage/shared@sdcard@g" )

        adb shell am start -n "$TEXT_EDITOR_APP" -d "file://"$real_file_path
    fi
}
alias dp-txt='droid-open-text-as-tmp'

function droid-reload-text-from-tmp()
{
    file=$1
    tmp_file=$(cat $file.tmp)
    mv $tmp_file $file
    rm $file.tmp
}
alias dp-txt-reload='droid-reload-text-from-tmp'

# Based on https://android.stackexchange.com/a/199496
function droid-get-open-chrome-tabs()
{
    if [ -z "$1" ]
    then
        session_file=$(gfind . -name '*.chrome-session' -type f -printf "%-.22T+ %M %n %-8u %-8g %8s %Tx %.8TX %p\n" | sort -r | awk '{print $9}' | head -1)
    else
        session_file=$1'.chrome-session'
    fi
    adb forward tcp:9222 localabstract:chrome_devtools_remote
    wget -O $TMP_DIR/tabs.json http://localhost:9222/json/list

    cat $TMP_DIR/tabs.json | grep 'url' | tr ',' ' ' |  awk '{print $2}' > $session_file
    session_size=$(cat $session_file | wc -l)
    echo 'Saved'$session_size' open tabs from Android Google Chrome into file '$session_file
}