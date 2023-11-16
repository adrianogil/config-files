
function mp3-extract-sample()
{
	input_file=$1
	start_time=$2  # 00:00:00
	end_time=$3    # 00:10:00
	output_file=$4

	ffmpeg -i ${input_file} -ss ${start_time} -to ${end_time} -c copy ${output_file}
}