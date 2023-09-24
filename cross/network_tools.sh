alias ips-net='ifconfig | grep net'
function ips()
{
    ifconfig | grep -E "([0-9]{1,3}\.){3}[0-9]{1,3}" | grep -v 127.0.0.1 | awk '{ print $2 }' | cut -f2 -d: | head -n1
}

function ips-external()
{
    curl -4 ifconfig.me
}

SSH_DEFAULT_PORT=7375

alias ssh2moi='ssh -p $SSH_DEFAULT_PORT'

function serverssh()
{
    if [ -z "$1" ]
    then
        ssh_port=$SSH_DEFAULT_PORT
    else
        ssh_port=$1
    fi
    echo "Starting sshd server using port "$ssh_port" on IP: "$(ips)
    sshd -p $ssh_port
}