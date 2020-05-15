
function github-save-repos-data()
{
    # Save repos from github
    # Using git hub command

    target_file=$1
    git hub repos > ${target_file}
}

function github-get-newest-fork()
{
    target_repo=$1
    curl -X GET https://api.github.com/repos/${target_repo}/forks?sort=newest
}