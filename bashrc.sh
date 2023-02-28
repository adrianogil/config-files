
if [[ "$(uname)" == "Darwin" ]]; then
    # OSX config
    source ${CONFIG_FILES_DIR}/osx/bashrc_osx.sh
elif [[ $0 == *termux* ]]; then
    # Termux config
    source ${CONFIG_FILES_DIR}/termux/bashrc_termux.sh
fi

# Cross config
source ${CONFIG_FILES_DIR}/cross/bashrc_cross.sh

# Slide tools
source ${CONFIG_FILES_DIR}/slide_tool/slide_tools.sh

# @tool gt-fz: Git Tools
function config-fz()
{
    configaction=$(find ${CONFIG_FILES_DIR}/*/ -name "*.sh" |  xargs -I {} cat {} | grep '# config-tools ' | cut -c16- | default-fuzzy-finder | tr ":" " " | awk '{print $1}')

    eval ${configaction}
}
alias cf-fz="config-fz"
