
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

function conv-m3u8-mp4()
{
    video_file=$1
    output_file="${video_file%%.*}".mp4

    ffmpeg -i "${video_file}" -c copy -bsf:a aac_adtstoasc "${output_file}"
}

function conv-m4a-to-mp3()
{
    # Based on this post: https://gist.github.com/christofluethi/646ae60d797a46a706a5
    ffmpeg $1.mp3 -i $1.m4a -codec:a libmp3lame -qscale:a 1
}

function conv-video-to-gif()
{
    # Based on this link: https://gist.github.com/vitorleal/563771e821cef668eef5

    video_file=$1
    gif_file="${video_file%%.*}".gif

    if [ -z "$2" ]
    then
        gif_delay='3'
        extra_options=''
    else
        gif_delay=$2
        if [ -z "$3" ]
        then
            extra_options=''
        else
            extra_options=$3 # like resolution: -s 600x400
        fi
    fi

    ffmpeg -i $video_file $extra_options -f gif - | gifsicle --optimize=0 --delay=$gif_delay > $gif_file
}

function conv-video-to-gif-batch()
{
    # Based on this link: https://gist.github.com/vitorleal/563771e821cef668eef5

    while test $# -gt 0
    do
        video_file=$1
        gif_file="${video_file%%.*}".gif
        ffmpeg -i $video_file -pix_fmt rgb24 -r 12 -f gif - | gifsicle --optimize=0 --delay=6 > $gif_file

        shift
    done
}

function conv-mov-to-mp4()
{
    # Based on https://stackoverflow.com/a/12026739
    video_file=$1
    output_file="${video_file%%.*}".mp4
    ffmpeg -i $video_file -vcodec copy -acodec copy $output_file
}