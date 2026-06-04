#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

run_step() {
    local label=$1
    shift

    printf '\n== %s ==\n' "$label"
    "$@"
}

check_shell_syntax() {
    local file

    while IFS= read -r -d '' file; do
        bash -n "$file"
    done < <(find "$repo_root" -name '*.sh' -not -path "$repo_root/.git/*" -print0)
}

check_bash_source() {
    CONFIG_FILES_DIR="$repo_root" bash --noprofile --norc -c 'source "$CONFIG_FILES_DIR/bashrc.sh"'
}

check_zsh_source() {
    if ! command -v zsh >/dev/null 2>&1; then
        printf 'zsh not found; skipping clean zsh source check.\n'
        return 0
    fi

    CONFIG_FILES_DIR="$repo_root" zsh -f -c 'source "$CONFIG_FILES_DIR/bashrc.sh"'
}

check_python_syntax() {
    python3 - "$repo_root/python" <<'PY'
import pathlib
import sys

root = pathlib.Path(sys.argv[1])
failed = False

for path in sorted(root.rglob("*.py")):
    try:
        source = path.read_text(encoding="utf-8")
        compile(source, str(path), "exec")
    except Exception as exc:
        failed = True
        print(f"{path}: {exc}", file=sys.stderr)

if failed:
    sys.exit(1)
PY
}

run_step "Shell syntax" check_shell_syntax
run_step "Clean bash source" check_bash_source
run_step "Clean zsh source" check_zsh_source
run_step "Python syntax" check_python_syntax

printf '\nSmoke tests passed.\n'
