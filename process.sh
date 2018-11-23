function ps-suspend()
{
    $PID=$1
    kill -SIGSTOP $PID
}

function ps-resume()
{
    $PID=$1
    kill -SIGCONT $PID
}