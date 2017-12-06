# Install Android APK
function ik()
{
    echo 'Searching for APK files ...'

    apk_file=$(find . -name '*.apk' | head -1)

    if [ -z $apk_file ]; then
        echo 'No APK Found!'
    else
        echo 'Found '$apk_file
        adb install -r $apk_file
    fi
}

# Android logcat
function dlog()
{
    device_model=$(adb shell getprop ro.product.model)
    echo "Device is $device_model"
    log_file=log_${device_model}_$(date +%F-%H:%M).txt
    echo 'Android log saved as '$log_file
    adb shell logcat -d -v time > $log_file
    number_of_lines=$(cat $log_file | wc -l)
    echo ''$number_of_lines' lines'
}

function logtext() {
    ls -t log_*.txt | head -1 | xargs -I {} cat {} | grep $1 | less
}

function catexception()
{
    ls -t log_*.txt | head -1 | xargs -I {} cat {} | python ${UNITY_BUILD_SCRIPTS_DIR}/android/log/error_log_filter.py
}

function logexception()
{
    catexception | less
}

# Cat last logcat saved by dlog
alias getlog='ls -t log_*.txt | head -1'
alias catlog='ls -t log_*.txt | head -1 | xargs -I {} cat {}'
alias openlog='ls -t log_*.txt | head -1 | xargs -I {} sublime {}'
alias gilcat='adb logcat | grep GilLog'

# Get info from connected device
alias droid-api='adb shell getprop ro.build.version.release'
alias droid-sdk='adb shell getprop ro.build.version.sdk'
