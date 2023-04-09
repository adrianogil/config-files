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

function ps-pick()
{
    target_pid=$(ps aux | default-fuzzy-finder | awk '{print $2}')
    echo $target_pid | copy-text-to-clipboard
    echo $target_pid
}

function ps-monitor()
{
    top -pid $(ps-pick)
}

alias k9="sudo kill -9 "

function ps-from-port()
{
	target_port=$1
	lsof -i :${target_port}
}
