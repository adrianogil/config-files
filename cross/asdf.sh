function _asdf-installed-tools()
{
    asdf plugin list 2>/dev/null | sed '/^[[:space:]]*$/d'
}

function _asdf-installed-versions()
{
    local tool=$1

    asdf list "$tool" 2>/dev/null |
        sed 's/^[*[:space:]]*//' |
        sed '/^[[:space:]]*$/d'
}

function _asdf-list-contains()
{
    local expected=$1

    grep -F -x -q "$expected"
}

function _asdf-supports-set()
{
    asdf help 2>/dev/null | grep -q 'asdf set '
}

function _asdf-configure-version()
{
    local scope=$1
    local tool=$2
    local version=$3
    local scope_label=.tool-versions

    if _asdf-supports-set
    then
        case "$scope" in
            current) asdf set "$tool" "$version" ;;
            home)
                scope_label='$HOME/.tool-versions'
                asdf set -u "$tool" "$version"
                ;;
            parent)
                scope_label='the closest parent .tool-versions'
                asdf set -p "$tool" "$version"
                ;;
        esac
    else
        case "$scope" in
            current) asdf local "$tool" "$version" ;;
            home)
                scope_label='$HOME/.tool-versions'
                asdf global "$tool" "$version"
                ;;
            parent)
                printf 'asdf-set-fzf: --parent requires an ASDF version with asdf set support\n' >&2
                return 1
                ;;
        esac
    fi || return 1

    printf 'Configured %s %s in %s.\n' "$tool" "$version" "$scope_label"
}

# config-tools asdf-set-fzf: Select an installed ASDF tool and version
function asdf-set-fzf()
{
    local scope=current
    local tool=""
    local version=""
    local tools=""
    local versions=""
    local selection=""

    while [ "$#" -gt 0 ]
    do
        case "$1" in
            --home|-u)
                if [ "$scope" != current ]; then
                    printf 'asdf-set-fzf: choose only one scope option\n' >&2
                    return 2
                fi
                scope=home
                shift
                ;;
            --parent|-p)
                if [ "$scope" != current ]; then
                    printf 'asdf-set-fzf: choose only one scope option\n' >&2
                    return 2
                fi
                scope=parent
                shift
                ;;
            -h|--help)
                printf 'Usage: asdf-set-fzf [--home|--parent] [tool [version]]\n'
                return 0
                ;;
            --)
                shift
                break
                ;;
            --*)
                printf 'Usage: asdf-set-fzf [--home|--parent] [tool [version]]\n' >&2
                return 2
                ;;
            *) break ;;
        esac
    done

    if [ "$#" -gt 2 ]
    then
        printf 'Usage: asdf-set-fzf [--home|--parent] [tool [version]]\n' >&2
        return 2
    fi

    tool="${1:-}"
    version="${2:-}"

    if ! command -v asdf >/dev/null 2>&1
    then
        printf 'asdf-set-fzf: asdf is required\n' >&2
        return 127
    fi
    if ! type default-fuzzy-finder >/dev/null 2>&1
    then
        printf 'asdf-set-fzf: default-fuzzy-finder is required\n' >&2
        return 127
    fi

    tools=$(_asdf-installed-tools) || return 1
    if [ -z "$tools" ]
    then
        printf 'asdf-set-fzf: no installed ASDF plugins found\n' >&2
        return 1
    fi

    if [ -z "$tool" ]
    then
        selection=$(
            printf '%s\n' "$tools" |
                default-fuzzy-finder --prompt='asdf tool> '
        ) || return 1
        [ -n "$selection" ] || return 1
        tool=$selection
    elif ! printf '%s\n' "$tools" | _asdf-list-contains "$tool"
    then
        printf 'asdf-set-fzf: plugin is not installed: %s\n' "$tool" >&2
        return 1
    fi

    versions=$(_asdf-installed-versions "$tool") || return 1
    if [ -z "$versions" ]
    then
        printf 'asdf-set-fzf: no installed versions found for %s\n' "$tool" >&2
        return 1
    fi

    if [ -z "$version" ]
    then
        selection=$(
            printf '%s\n' "$versions" |
                default-fuzzy-finder --prompt="asdf ${tool} version> "
        ) || return 1
        [ -n "$selection" ] || return 1
        version=$selection
    elif ! printf '%s\n' "$versions" | _asdf-list-contains "$version"
    then
        printf 'asdf-set-fzf: version is not installed for %s: %s\n' \
            "$tool" "$version" >&2
        return 1
    fi

    _asdf-configure-version "$scope" "$tool" "$version"
}

alias aff='asdf-set-fzf'
