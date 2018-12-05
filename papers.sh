
function papers-title()
{
    # Using TMP_DIR from my dotfiles
    # (See https://github.com/adrianogil/dotfiles/blob/master/osx/export.sh#L1)

    # Using pdftotext
    # On Mac you can install by:
    #       brew install poppler

    target_pdf=$1

    python2 ${CONFIG_FILES_DIR}/python/papers/paper_title.py $target_pdf
}