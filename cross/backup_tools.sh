
TMP_BKP_DIR=/tmp/backup


# config-tools bkp: bkp a file or folder
function bkp()
{
    target=$1
    if [ -z "$target" ]
    then
        echo "Usage: bkp <target>"
        return
    fi

    current_date_prefix=$(date +%Y%m%d%H%M%S)
    current_date_path=$(date +%Y/%m/%Y.%mW%W)

    mkdir -p $TMP_BKP_DIR/$current_date_path/

    if [ -d $target ]
    then
        folder_name=$(basename $target)
        folder_path=$(dirname $target)
        echo "Backing up directory "$target
        cp -r $target $TMP_BKP_DIR/$current_date_path/
        cp -r $target $folder_path/.bkp_$folder_name.$current_date_prefix
    else
        echo "Backing up file "$target
        file_name=$(basename $target)
        file_path=$(dirname $target)
        cp $target $TMP_BKP_DIR/$current_date_path/
        cp $target $file_path/.bkp_$file_name.$current_date_prefix
    fi
}

# config-tools bkp-restore: restore a file or folder
function bkp-restore()
{
    target=$1
    if [ -z "$target" ]
    then
        echo "Usage: bkp-restore <target>"
        return
    fi

    if [ -d $target ]
    then
        folder_name=$(basename $target)
        folder_path=$(dirname $target)
        echo "Restoring directory "$target
        target_bkp_folder=$(ls -d $folder_path/.bkp_$folder_name.* | tail -n 1)
        # Check if backup folder exists
        if [ -z "$target_bkp_folder" ]
        then
            target_bkp_folder=$(ls -d $TMP_BKP_DIR/*/$folder_name | tail -n 1)
            if [ -z "$target_bkp_folder" ]
            then
                echo "No backup found for "$target
                return
            else
                cp -r $target_bkp_folder $target
            fi
        else
            cp -r $target_bkp_folder $target
        fi
    else
        echo "Restoring file "$target
        file_name=$(basename $target)
        file_path=$(dirname $target)
        target_bkp_file=$(ls $file_path/.bkp_$file_name.* | tail -n 1)
        # Check if backup file exists
        if [ -z "$target_bkp_file" ]
        then
            target_bkp_file=$(ls $TMP_BKP_DIR/*/$file_name | tail -n 1)
            if [ -z "$target_bkp_file" ]
            then
                echo "No backup found for "$target
                return
            else
                cp $target_bkp_file $target
            fi
        else
            cp $target_bkp_file $target
        fi
    fi
}