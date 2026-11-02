# Resolve a real Python 3 interpreter, ignoring Windows Store execution aliases.
CONFIG_TOOLS_PYTHON_EXECUTABLE=
CONFIG_TOOLS_PYTHON_LAUNCHER=
CONFIG_TOOLS_PYTHON_NATIVE=
for _config_python_candidate in python3 python py; do
    if command -v "$_config_python_candidate" >/dev/null 2>&1; then
        if [[ $_config_python_candidate == py ]]; then
            _config_python_version_arg=-3
        else
            _config_python_version_arg=
        fi
        if "$_config_python_candidate" ${_config_python_version_arg:+"$_config_python_version_arg"} -c 'import sys; sys.exit(sys.version_info.major != 3)' >/dev/null 2>&1; then
            CONFIG_TOOLS_PYTHON_EXECUTABLE=$_config_python_candidate
            CONFIG_TOOLS_PYTHON_LAUNCHER=$_config_python_version_arg
            break
        fi
    fi
done
unset _config_python_candidate _config_python_version_arg
if [[ -n $CONFIG_TOOLS_PYTHON_EXECUTABLE ]]; then
    if [[ $("$CONFIG_TOOLS_PYTHON_EXECUTABLE" ${CONFIG_TOOLS_PYTHON_LAUNCHER:+"$CONFIG_TOOLS_PYTHON_LAUNCHER"} -c 'import os; print(os.name)' | tr -d '\r') == nt ]]; then
        CONFIG_TOOLS_PYTHON_NATIVE=1
    fi
fi

function config-python()
{
    if [[ ${1:-} == --available ]]; then
        [[ -n $CONFIG_TOOLS_PYTHON_EXECUTABLE ]]
        return $?
    fi
    if [[ -z $CONFIG_TOOLS_PYTHON_EXECUTABLE ]]; then
        printf 'Python 3 is required; install Python 3 with python or py on PATH, then reload the shell.\n' >&2
        return 127
    fi
    if [[ -n $CONFIG_TOOLS_PYTHON_NATIVE ]] && command -v cygpath >/dev/null 2>&1; then
        MSYS2_ENV_CONV_EXCL=PYTHONPATH CONFIG_FILES_DIR="$(cygpath -aw "$CONFIG_FILES_DIR")" \
            "$CONFIG_TOOLS_PYTHON_EXECUTABLE" ${CONFIG_TOOLS_PYTHON_LAUNCHER:+"$CONFIG_TOOLS_PYTHON_LAUNCHER"} "$@"
    else
        "$CONFIG_TOOLS_PYTHON_EXECUTABLE" ${CONFIG_TOOLS_PYTHON_LAUNCHER:+"$CONFIG_TOOLS_PYTHON_LAUNCHER"} "$@"
    fi
}

if [[ -z ${CONFIG_TOOLS_PYTHON_PATH:-} ]]; then
    export CONFIG_TOOLS_PYTHON_PATH="$CONFIG_FILES_DIR/python/"
    _config_python_path=$CONFIG_TOOLS_PYTHON_PATH
    _config_python_separator=:
    if [[ -n $CONFIG_TOOLS_PYTHON_NATIVE ]] && command -v cygpath >/dev/null 2>&1; then
        _config_python_path=$(cygpath -w "$_config_python_path")
        _config_python_separator=';'
    fi
    export PYTHONPATH="$_config_python_path${PYTHONPATH:+$_config_python_separator$PYTHONPATH}"
    unset _config_python_path _config_python_separator
fi
