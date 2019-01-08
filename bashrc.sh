
if [ "$(uname)" == "Darwin" ]; then
    # OSX config
    source ${CONFIG_FILES_DIR}/osx/bashrc_osx.sh
elif [[ $0 == *termux* ]]; then
    # Termux config
    source ${CONFIG_FILES_DIR}/termux/bashrc_termux.sh
fi

source ${CONFIG_FILES_DIR}/cross/bashrc_cross.sh

# Slide tools
source ${CONFIG_FILES_DIR}/slide_tool/slide_tools.sh