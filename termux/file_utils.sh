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

function open-text()
{
    echo "Open text file "$1"using DroidEdit Free"

    real_file_path=$(abspath $1)
    real_file_path=$(echo $real_file_path | sed "s@data/data/com.termux/files/home/storage/shared@sdcard@g" )

    am start -n "$TEXT_EDITOR_APP" -d "file://"$real_file_path
}
alias otxt='open-text'

function open-text-as-tmp()
{
    file=$1

    echo "Open text file "$file" in a tmp folder using DroidEdit Free"

    filename=$(basename -- "$file")
    file_dir="${file%$filename}"

    tmp_path=/sdcard/tmp/tmp_$filename

    cp $file $tmp_path
    echo "$file" > "/sdcard/tmp/.tmp_$filename_info"
    echo "$tmp_path" >> "/sdcard/tmp/.tmp_$filename_info"

    echo $tmp_path > $file.tmp
    text_file=$tmp_path

    real_file_path=$(abspath $text_file)
    real_file_path=$(echo $real_file_path | sed "s@data/data/com.termux/files/home/storage/shared@sdcard@g" )

    am start -n "$TEXT_EDITOR_APP" -d "file://"$real_file_path
}
alias otxt-tmp='open-text-as-tmp'

function txt-reload-from-tmp()
{
    file=$1
    tmp_file=$(cat $file.tmp)
    mv $tmp_file $file
    rm $file.tmp
}
alias otxt-reload='txt-reload-from-tmp'

function txt-reload-all()
{
    for f in `find /sdcard/tmp/ -name '.tmp_*info'`; 
    do
        original_file=$(cat f | head -1)
        tmp_file=$(cat f | tail -1)

        mv $tmp_file $original_file
        rm $original_file.tmp
    done
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
    elif [ ${file: -3} == ".py" ]; then
        open-text $file
    elif [ ${file: -3} == ".sh" ]; then
        open-text $file
    elif [ ${file: -4} == ".cpp" ]; then
        open-text $file
    elif [ ${file: -4} == ".h" ]; then
        open-text $file
    elif [ ${file: -4} == ".md" ]; then
        open-text $file
    elif [ ${file: -15} == ".chrome-session" ]; then
        open-text $file
    else
        open-file $file
    fi
}

alias o="open"
