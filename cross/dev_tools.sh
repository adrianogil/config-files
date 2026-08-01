

function swagger-generate-html()
{
    # Generate HTML documentation from Swagger YAML
    target_swagger_yaml_file=$1
    target_html_file=$2

    cat ${target_swagger_yaml_file} |  python3 ${CONFIG_FILES_DIR}/python/swagger/swagger.py > ${target_html_file}
}

# Search and execute bash scripts
function sha()
{
    target_shellscript=$(find . -name '*.sh' | default-fuzzy-finder)
    echo 'Running '${target_shellscript}
    ${target_shellscript}
}

# config-tools json-fmt: Validate and pretty-print JSON from a file or stdin
function json-fmt()
{
    local input_file="${1:-}"

    if [[ $# -gt 1 ]]; then
        printf 'Usage: json-fmt [file|-]\n' >&2
        return 2
    fi

    if [[ -n $input_file && $input_file != - && ! -r $input_file ]]; then
        printf 'json-fmt: %s: No such readable file\n' "$input_file" >&2
        return 1
    fi

    if command -v jq >/dev/null 2>&1; then
        if [[ -n $input_file && $input_file != - ]]; then
            jq . -- "$input_file"
        else
            jq .
        fi
        return $?
    fi

    if ! command -v python3 >/dev/null 2>&1; then
        printf 'json-fmt: install jq or Python 3 to format JSON\n' >&2
        return 127
    fi

    if [[ -n $input_file && $input_file != - ]]; then
        python3 -c 'import json, sys
with open(sys.argv[1], encoding="utf-8") as source:
    data = json.load(source)
json.dump(data, sys.stdout, ensure_ascii=False, indent=2)
print()' "$input_file"
    else
        python3 -c 'import json, sys
data = json.load(sys.stdin)
json.dump(data, sys.stdout, ensure_ascii=False, indent=2)
print()'
    fi
}

# config-tools command-benchmark: Benchmark repeated command execution
function command-benchmark()
{
    local runs="${1:-}"

    if [[ $# -lt 2 || ! $runs =~ ^[1-9][0-9]*$ ]]; then
        printf 'Usage: command-benchmark <runs> <command...>\n' >&2
        return 2
    fi

    if ! command -v python3 >/dev/null 2>&1; then
        printf 'command-benchmark: Python 3 is required\n' >&2
        return 127
    fi

    if [[ -z ${CONFIG_FILES_DIR:-} ]]; then
        printf 'command-benchmark: CONFIG_FILES_DIR is not set\n' >&2
        return 1
    fi

    python3 "$CONFIG_FILES_DIR/python/clitools/command_benchmark.py" "$@"
}

# config-tools dotenv-check: Validate dotenv syntax and duplicate definitions
function dotenv-check()
{
    local dotenv_file="${1:-.env}"

    if [[ $# -gt 1 ]]; then
        printf 'Usage: dotenv-check [file]\n' >&2
        return 2
    fi

    if [[ ! -f $dotenv_file ]]; then
        printf 'dotenv-check: %s: No such file\n' "$dotenv_file" >&2
        return 1
    fi

    if ! command -v python3 >/dev/null 2>&1; then
        printf 'dotenv-check: Python 3 is required\n' >&2
        return 127
    fi

    if [[ -z ${CONFIG_FILES_DIR:-} ]]; then
        printf 'dotenv-check: CONFIG_FILES_DIR is not set\n' >&2
        return 1
    fi

    python3 "$CONFIG_FILES_DIR/python/clitools/dotenv_check.py" "$dotenv_file"
}

function jabba-check-instslled-versions()
{
    jabba ls    
}


function jabba-install-java()
{
    jabba install $(jabba ls-remote | default-fuzzy-finder)
}

function jabba-uninstall-java()
{
    jabba uninstall $(jabba ls | default-fuzzy-finder)
}

function config-install-jabba()
{
    curl -sL https://github.com/shyiko/jabba/raw/master/install.sh | bash && . ~/.jabba/jabba.sh
}
