
CROSS_CONFIG_FILES_DIR=$CONFIG_FILES_DIR/cross/


# General useful aliases
source ${CROSS_CONFIG_FILES_DIR}/useful_aliases.sh
# Fancy colors
case $SHELL in
*/zsh) 
   # assume Zsh
   ;;
*/bash)
   # assume Bash
   source ${CROSS_CONFIG_FILES_DIR}/fancy_colors.sh
   ;;
*)
   # assume something else
esac
# Path Tools
source ${CROSS_CONFIG_FILES_DIR}/path_tools.sh
# Find Tools
source ${CROSS_CONFIG_FILES_DIR}/find_tools.sh
# File conversions
source ${CROSS_CONFIG_FILES_DIR}/file_conversions.sh
# Screen Management
source ${CROSS_CONFIG_FILES_DIR}/screen_management.sh
# Korean
source ${CROSS_CONFIG_FILES_DIR}/korean.sh
# Hdev
source ${CROSS_CONFIG_FILES_DIR}/hdev.sh
# Github-related functions
source ${CROSS_CONFIG_FILES_DIR}/github.sh
# Docker-related functions
source ${CROSS_CONFIG_FILES_DIR}/docker.sh
# process-related functions
source ${CROSS_CONFIG_FILES_DIR}/process_utils.sh
# Math functions
source ${CROSS_CONFIG_FILES_DIR}/math_tools.sh
# Dev Tools
source ${CROSS_CONFIG_FILES_DIR}/dev_tools.sh
# Basic CMDs
source ${CROSS_CONFIG_FILES_DIR}/basic_cmds.sh

function zap()
{
   target_number=$1
   if [ -z "$target_number" ]
   then
         echo "Number to send message: "
         read target_number
   fi

   if [ -z "$target_number" ]
   then
         echo "Missing a number!"
   else
         open "https://api.whatsapp.com/send/?phone="${target_number}
   fi
}

