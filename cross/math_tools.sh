

alias time-calc='config-python "${CONFIG_FILES_DIR}/python/clitools/timecalc.py"'
alias plot-cmd='config-python "${CONFIG_FILES_DIR}/python/plottool/plot_command.py"'

# config-tools duration-human: Convert seconds to a duration or a duration to seconds
function duration-human()
{
    if ! config-python --available; then
        printf 'duration-human: Python 3 is required\n' >&2
        return 127
    fi

    if [[ -z ${CONFIG_FILES_DIR:-} ]]; then
        printf 'duration-human: CONFIG_FILES_DIR is not set\n' >&2
        return 1
    fi

    config-python "$CONFIG_FILES_DIR/python/clitools/duration_human.py" "$@"
}
