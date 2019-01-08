function fleditor-android()
{
    real_file_path=$(abspath $1)
    real_file_path=$(echo $real_file_path | sed "s@data/data/com.termux/files/home/storage/shared@sdcard@g" )
    echo "Open file "$1"using DroidEdit Free"
    am start -n "com.aor.droidedit/.DroidEditFreeActivity" -d "file://"$real_file_path
}

function abspathcp()
{
    termux-clipboard-set $(abspath $1)
}