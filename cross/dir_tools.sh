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

# config-tools cdk: Enter a directory from using default-fuzzy-finder
function cdk()
{
    cd "$(find . -type d -regex '\./[^.]*$' | default-fuzzy-finder)"
}

# config-tools cdback: Fuzzy-search and enter a directory from cd stack
function cdback() {
    last_path=$(dirs -lv | default-fuzzy-finder | awk '{$1=""; print substr($0,2)}')
    cd "${last_path}"
}
