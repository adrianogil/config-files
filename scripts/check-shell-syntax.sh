#!/bin/sh

set -u

repo_root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)

check_with_shell() {
    shell_name=$1
    shell_suffix=$2

    if ! command -v "$shell_name" >/dev/null 2>&1; then
        printf 'SKIP: %s is unavailable; %s syntax was not checked.\n' \
            "$shell_name" "$shell_suffix"
        return 0
    fi

    find "$repo_root" -type f \
        \( -name '*.sh' -o -name "*.$shell_suffix" \) \
        -not -path "$repo_root/.git/*" -print | sort | {
        checked=0
        failed=0

        while IFS= read -r file; do
            checked=$((checked + 1))
            if ! "$shell_name" -n "$file"; then
                printf 'FAIL [%s]: %s\n' "$shell_name" "${file#"$repo_root"/}" >&2
                failed=$((failed + 1))
            fi
        done

        if [ "$failed" -ne 0 ]; then
            printf 'FAIL: %s found syntax errors in %d of %d files.\n' \
                "$shell_name" "$failed" "$checked" >&2
            return 1
        fi

        printf 'PASS: %s parsed %d files successfully.\n' "$shell_name" "$checked"
    }
}

status=0

# The repo's .sh modules are sourced by both Bash and Zsh. Files ending in
# .bash or .zsh are checked only by their corresponding parser.
check_with_shell bash bash || status=1
check_with_shell zsh zsh || status=1

exit "$status"
