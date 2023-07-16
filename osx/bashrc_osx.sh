# Add this to your profile file
# export CONFIG_FILES_PATH=/<PATH>/config-files/
# source ${CONFIG_FILES_PATH}/bashrc.sh

OSX_CONFIG_FILES_DIR=$CONFIG_FILES_DIR/osx/

source ${OSX_CONFIG_FILES_DIR}/text_utils.sh
source ${OSX_CONFIG_FILES_DIR}/sublime.sh
# General alias
source ${OSX_CONFIG_FILES_DIR}/path_tools.sh
source ${OSX_CONFIG_FILES_DIR}/useful_aliases.sh
# OSX Browser-related tools
source ${OSX_CONFIG_FILES_DIR}/browser.sh
# Papers-related tools
source ${OSX_CONFIG_FILES_DIR}/papers.sh
# Function to ease install operations
source ${OSX_CONFIG_FILES_DIR}/install.sh

source ${OSX_CONFIG_FILES_DIR}/general_utils.sh
