
alias youtube-dl-mp3='youtube-dl -x --audio-format "mp3" '

function youtube-dl-mp3-from-playlist()
{
    youtube-dl -j --flat-playlist $1 | jq -r '.id' | sed 's_^_https://youtube.com/v/_' | cut -c9- | xa youtube-dl  -x --audio-format "mp3" {}
}

# Based on https://stackoverflow.com/questions/18444194/cutting-the-videos-based-on-start-and-end-time-using-ffmpeg
function video-cut()
{
    target_video=$1
    output_video=$2
    start_time=$3    # 00:00:03
    duration_time=$4 # 00:00:08
    ffmpeg -i $target_video -ss $start_time -t $duration_time -async 1 $output_video
}