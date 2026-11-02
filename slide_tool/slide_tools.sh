
function markdown-to-slides()
{

    TMP_CONTENT_FILE='tmp_content.txt'

    echo "" > $TMP_CONTENT_FILE

    while test $# -gt 0
    do
        cat "$1" >> "$TMP_CONTENT_FILE"

        shift
    done

    config-python "${CONFIG_FILES_DIR}/slide_tool/generate_slide.py"

    rm $TMP_CONTENT_FILE
}
