
function papers-title()
{
    # Using TMP_DIR from my dotfiles
    # (See https://github.com/adrianogil/dotfiles/blob/master/osx/export.sh#L1)

    # Using pdftotext
    # On Mac you can install by:
    #       brew install poppler

    target_pdf=$1

    pdftotext -raw $target_pdf $TMP_DIR/paper_text.txt
    cat $TMP_DIR/paper_text.txt | head -1
}