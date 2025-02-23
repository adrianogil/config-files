
# config-tools cf-cp-fz: Copy by selecting target file using default-fuzzy-finder
function cf-cp-fz()
{
	destination_file=$1
	target_file=$(find . | default-fuzzy-finder)

	cp ${target_file} ${destination_file}
	echo "Copied "${target_file}" as "${destination_file}
}
alias cp-fz="cf-cp-fz"

# config-tools myvars: List all variables names and their current values
function myvars()
{
	printenv | less
}

# config-tools which-shell: Print the shell name
function which-shell()
{
    ps -p $$ -o pid,comm=
}
