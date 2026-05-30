if [ -z "$CURRENT_LLM" ]; then
    if command -v codex >/dev/null 2>&1; then
        export CURRENT_LLM="codex"
    else
        export CURRENT_LLM="gemini"
    fi
fi

function _gemini_cli_command()
{
    if command -v gemini >/dev/null 2>&1; then
        echo "gemini"
    elif command -v gemini-cli >/dev/null 2>&1; then
        echo "gemini-cli"
    else
        return 1
    fi
}

function codex-prompt()
{
    codex exec "$*"
}

function gemini-prompt()
{
    local gemini_cmd
    gemini_cmd=$(_gemini_cli_command) || return 1
    "$gemini_cmd" -p "$*"
}

function llm-prompt()
{
    case "$CURRENT_LLM" in
        codex)
            codex-prompt "$@"
            ;;
        gemini|gemini-cli)
            gemini-prompt "$@"
            ;;
        *)
            "$CURRENT_LLM" "$@"
            ;;
    esac
}

alias p='llm-prompt'

function codex-chat()
{
    codex "$@"
}

function gemini-chat()
{
    local gemini_cmd
    gemini_cmd=$(_gemini_cli_command) || return 1
    "$gemini_cmd" "$@"
}

function llm-chat()
{
    case "$CURRENT_LLM" in
        codex)
            codex-chat "$@"
            ;;
        gemini|gemini-cli)
            gemini-chat "$@"
            ;;
        *)
            "$CURRENT_LLM" "$@"
            ;;
    esac
}

alias lr='llm-chat'
