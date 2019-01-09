function open-pdf()
{
    echo "Open PDF file "$1

    real_file_path=$(abspath $1)
    real_file_path=$(echo $real_file_path | sed "s@data/data/com.termux/files/home/storage/shared@sdcard@g" )

    echo "Open PDF file from path: "$real_file_path

    am start -a android.intent.action.VIEW -d  "file://"$real_file_path -t "application/pdf"
}

function open-model()
{
    # 3D_VIEWER_APP macro is defined in dotfiles repo
    echo "Open file "$1"using ModelViewer"

    real_file_path=$(abspath $1)
    real_file_path=$(echo $real_file_path | sed "s@data/data/com.termux/files/home/storage/shared@sdcard@g" )

    echo "Open file from path "$real_file_path

    am start -n "$MODEL3D_VIEWER_APP" -d "file://"$real_file_path
}

function open-file()
{
    echo "Open file "$1

    real_file_path=$(abspath $1)
    real_file_path=$(echo $real_file_path | sed "s@data/data/com.termux/files/home/storage/shared@sdcard@g" )

    echo "Open file with path: "$real_file_path

    am start -a android.intent.action.VIEW -d  "file://"$real_file_path
}

function open()
{
    file=$1

    if [ ${file: -4} == ".pdf" ]; then
        open-pdf $file
    elif [ ${file: -4} == ".stl" ]; then
        open-model $file
    elif [ ${file: -4} == ".txt" ]; then
        open-text $file
    elif [ ${file: -5} == ".note" ]; then
        open-text $file
    else
        open-file $file
    fi
}

alias o="open"
