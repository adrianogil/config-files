function workspace()
{
    cd ${WORKSPACE_DIR}
}

# Directory creation
function md()
{
    echo 'Creating directory '$1
    mkdir -p $1
}

function mdd()
{
    echo 'Creating directory '$1
    mkdir -p $1
    echo 'Entrying directory '$1
    cd $1
}

function mddate()
{
    target_directory=$(date +%Y%m%d%H%M)

    echo 'Creating directory '${target_directory}
    mkdir -p ${target_directory}
    echo 'Entrying directory '${target_directory}
    cd ${target_directory}
}

alias mp='mkdir -p'

function cd_up() {
  cd $(printf "%0.s../" $(seq 1 $1 ));
}
alias 'cd..'='cd_up'

# Navigation
alias ..="cd .."
alias ...="cd ../.."
alias ....="cd ../../.."
alias .....="cd ../../../.."

# Enter a directory from sk
# sk  = https://github.com/lotabout/skim
function cdk()
{
    cd "$(find . -type d -regex '\./[^.]*$' | default-fuzzy-finder)"
}

function cd-fz()
{
    cd $(dirname $(fzf))
}

# config-tools cdback: Fuzzy-search and enter a directory from cd stack
function cdback()
{
    cd $(dirs -lv | default-fuzzy-finder | awk '{print $2}')
}
