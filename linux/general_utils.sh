

# Resolve a target while protecting against circular alias chains.
function _see-definition()
{
    local target_function=$1
    local resolution_depth=${2:-0}
    local alias_definition
    local alias_value
    local alias_target

    if [ "${resolution_depth}" -ge 20 ]
    then
        printf 'Alias resolution limit reached at %s (possible circular alias).\n' "${target_function}" >&2
        return 1
    fi

    if alias_definition=$(alias "${target_function}" 2>/dev/null)
    then
        # Bash prefixes alias output with "alias "; Zsh does not. In both
        # shells, everything after the first equals sign is the alias value.
        alias_value=${alias_definition#*=}
        case "${alias_value}" in
            \'*\') alias_value=${alias_value#\'}; alias_value=${alias_value%\'} ;;
            \"*\") alias_value=${alias_value#\"}; alias_value=${alias_value%\"} ;;
        esac
        alias_value="${alias_value#"${alias_value%%[![:space:]]*}"}"
        alias_target=${alias_value%%[[:space:];|&]*}
        alias_target=${alias_target#\\}

        if [ -z "${alias_target}" ]
        then
            printf 'see-definition: alias %s has no command to inspect\n' \
                "${target_function}" >&2
            return 1
        fi

        printf '%s is alias (%s)\n' "${target_function}" "${alias_value}"
        _see-definition "${alias_target}" "$((resolution_depth + 1))"
        return
    fi

    if type whence >/dev/null 2>&1
    then
        whence -f "${target_function}"
    else
        type "${target_function}"
    fi
}

function see-definition()
{
    local target_function

    if [ -z "${1:-}" ]
    then
        printf "Enter target function: "
        read -r target_function
    else
        target_function=$1
    fi

    _see-definition "${target_function}" 0
}
alias sd="see-definition"
