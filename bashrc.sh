
if [[ "$(uname)" == "Darwin" ]]; then
    # OSX config
    source ${CONFIG_FILES_DIR}/osx/bashrc_osx.sh
elif [ "$(expr substr $(uname -s) 1 5)" == "Linux" ]; then
    # Linux config
    source ${CONFIG_FILES_DIR}/linux/bashrc_linux.sh
elif [[ $0 == *termux* ]]; then
    # Termux config
    source ${CONFIG_FILES_DIR}/termux/bashrc_termux.sh
fi

# Cross config
source ${CONFIG_FILES_DIR}/cross/bashrc_cross.sh

# Slide tools
source ${CONFIG_FILES_DIR}/slide_tool/slide_tools.sh

# @tool config-fz: Config Tools
function config-fz()
{
    # Run a ConfigFiles command using default-fuzzy-finder
    config_action=$(find ${CONFIG_FILES_DIR}/*/ -name "*.sh" |  xargs -I {} cat {} | grep '# config-tools ' | cut -c16- | default-fuzzy-finder | tr ":" " " | awk '{print $1}')
    echo "Running "${config_action}

    eval ${config_action}
}
alias cf-fz="config-fz"
