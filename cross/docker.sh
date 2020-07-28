

function df-inspect-using-bash()
{
    target_image=$1

    docker run -it --entrypoint /bin/sh ${target_image}
}