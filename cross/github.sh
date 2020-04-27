
function github-save-repos-data()
{
    # Save repos from github
    # Using git hub command

    target_file=$1
    git hub repos > ${target_file}
}