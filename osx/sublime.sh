if ! command -v sublime &> /dev/null
then
    alias sublime=subl
fi

alias main-code-editor="sublime"

alias s="sublime"
alias sw="sublime -n"

alias smw='smerge-open'

function smerge-open()
{
    if [ -z "$1" ]
    then
          smerge -n .
    else
          smerge -n $1
    fi
}

function sublimeb
{
    # Send text content to Sublime buffer
    sublime --command 'insert_snippet {"contents" : "'$1'"}'
}

function sg()
{
    # Open new file into sublime and add it to git
    new_file=$1

    tg ${new_file}
    sublime ${new_file}
}

function sgx()
{
    # Open new file into sublime and add it to git
    new_file=$1

    sg ${new_file}
    chmod +x ${new_file}
}

function sublime-create-pkg-link()
{
	current_plugin=$PWD
	plugin_name=$(basename ${current_plugin})

    sublime_packages_folder=$(mydirs -p sublime-packages)

	target_folder="${sublime_packages_folder}"/${plugin_name}

	echo "Creating Sublime plugin: "${plugin_name}" at folder "${target_folder}

	ln -sf ${current_plugin} "${target_folder}"
}
