
function fpdf
{
    if [ -z "$2" ]
    then
        target_directory='.'
    else
        target_directory=$2
    fi

     find $target_directory -iname '*.pdf' -exec pdfgrep $1 {} +
}

# Function to find files in a directory
function f
{
    if [ -z "$1" ]
    then
        echo 'usage: f <search_string> <path>'
    else
        if [[ "$1" == "-v" ]]; then
            if [ -z "$3" ]
            then
                target_directory='.'
            else
                target_directory=$3
            fi

            echo "Trying to search "$2" in directory "$target_directory
            echo ""

            find $target_directory -name "$2"
        else
            if [ -z "$2" ]
            then
                target_directory='.'
            else
                target_directory=$2
            fi

            find $target_directory -name "$1"
        fi
    fi
}

function ffz
{
    f "$1" "$2" "$3" | default-fuzzy-finder
}

function ffz-sh
{
    f "$1" "$2" "$3" | default-fuzzy-finder | sh
}

function ffz-cp
{
    f "$1" "$2" "$3" | default-fuzzy-finder | copy-clipboard-function
}

function fcount-subdirs()
{
    target_directory=$1
    if [ -z "$2" ]
    then
        file_name='*'
    else
        file_name=$2
    fi

    for i in `find $target_directory -d -maxdepth 1`;
    do
        n=$(fcount "$file_name" $i)
        echo $i": "$n" files ("$(du -sh $i | awk '{print $1}')")"
    done;
}

function fcount
{
    if [ -z "$1" ]
    then
        echo 'usage: f <search_string> <path>'
    else
        if [[ "$1" == "-v" ]]; then
            if [ -z "$3" ]
            then
                target_directory='.'
            else
                target_directory=$3
            fi

            echo "Trying to search "$2" in directory "$target_directory
            echo ""

            find $target_directory -name "$2" | wc -l
        else
            if [ -z "$2" ]
            then
                target_directory='.'
            else
                target_directory=$2
            fi

            find $target_directory -name "$1" | wc -l
        fi
    fi
}