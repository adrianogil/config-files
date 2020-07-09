alias s="sublime"
alias sw="sublime -n"


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

function sublime-create-pkg-link()
{
	current_plugin=$PWD
	plugin_name=$(basename ${current_plugin})

	target_folder="$HOME/Library/Application Support/Sublime Text 3/Packages/"${plugin_name}

	echo "Creating Sublime plugin: "${plugin_name}" at folder "${target_folder}

	ln -sf ${current_plugin} "${target_folder}"
}