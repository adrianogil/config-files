alias p2='python2'
alias p3='python3'

function p3m()
{
    module_path=$1
    target_module=$(echo ${module_path} | tr '/' '.')
    target_module=${target_module/.py/}
    echo "Running module "${target_module}
    shift
    python3 -m ${target_module} $@
}

alias pi='pip install'