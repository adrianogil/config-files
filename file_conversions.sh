
function conv-webp-jpg()
{
    webp_file=$1

    if [ -z "$1" ]
    then
        target_output='out.jpg'
    else
        target_output=$1
    fi

    ffmpeg -i $webp_file $target_output
}

function conv-m4a-to-mp3()
{
    # Based on this post: https://gist.github.com/christofluethi/646ae60d797a46a706a5
    ffmpeg $1.mp3 -i $1.m4a -codec:a libmp3lame -qscale:a 1
}