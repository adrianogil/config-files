

alias time-calc='python3 ${CONFIG_FILES_DIR}/python/clitools/timecalc.py'
alias plot-cmd='python ${CONFIG_FILES_DIR}/python/plottool/plot_command.py'

# config-tools duration-human: Convert seconds to a duration or a duration to seconds
function duration-human()
{
    if ! command -v python3 >/dev/null 2>&1; then
        printf 'duration-human: Python 3 is required\n' >&2
        return 127
    fi

    if [[ -z ${CONFIG_FILES_DIR:-} ]]; then
        printf 'duration-human: CONFIG_FILES_DIR is not set\n' >&2
        return 1
    fi

    python3 "$CONFIG_FILES_DIR/python/clitools/duration_human.py" "$@"
}
