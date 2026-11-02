#!/usr/bin/env bash
# Portable argument/dispatch tests; real desktop and network checks are separate.
set -eo pipefail
repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
case "$(uname -s)" in
    MINGW*|MSYS*) ;;
    *) printf 'SKIP: Windows checks require Git Bash.\n'; exit 0 ;;
esac

test_root=$(mktemp -d "$repo_root/.windows-test.XXXXXX")
cleanup() {
    # Only remove the explicitly created test directory inside this repository.
    if [[ $test_root == "$repo_root"/.windows-test.* && -d $test_root ]]; then
        rm -rf -- "$test_root"
    fi
}
trap cleanup EXIT
mkdir "$test_root/config files Unicode ñ"
for entry in bashrc.sh cross linux osx termux python slide_tool windows; do
    cp -R "$repo_root/$entry" "$test_root/config files Unicode ñ/"
done
export CONFIG_FILES_DIR="$test_root/config files Unicode ñ"
export TERM=xterm-256color
source "$CONFIG_FILES_DIR/bashrc.sh"
[[ $TERM == xterm-256color ]]
type _windows-call >/dev/null
type config-python >/dev/null
if config-python --available; then
    config-python -c 'import os, pathlib, sys
assert pathlib.Path(os.environ["CONFIG_FILES_DIR"]).is_dir()
assert pathlib.Path(sys.argv[1]).is_file()' "$CONFIG_FILES_DIR/bashrc.sh"
fi

# Exercise the existing loaders in clean Bash processes with platform detection
# stubbed; this does not emulate macOS/Linux utilities or replace native CI.
cat > "$test_root/check-platform.sh" <<'SH'
uname() { printf '%s\n' "$CF_TEST_PLATFORM"; }
source "$CONFIG_FILES_DIR/bashrc.sh"
if type _windows-call >/dev/null 2>&1; then exit 1; fi
type _clipboard-system-set >/dev/null
case "$CF_TEST_PLATFORM" in
    Darwin) [[ -n $OSX_CONFIG_FILES_DIR ]] ;;
    Linux) [[ -n $LINUX_CONFIG_FILES_DIR ]] ;;
esac
SH
CF_TEST_PLATFORM=Darwin "$BASH" --noprofile --norc "$test_root/check-platform.sh"
CF_TEST_PLATFORM=Linux "$BASH" --noprofile --norc "$test_root/check-platform.sh"

# Preserve data with spaces, Unicode and PowerShell metacharacters verbatim.
_windows-call() { printf '%s\n%s' "$1" "${2:-}"; }
target="$test_root/ñ space ' \$value ; [test].txt"
printf 'test' > "$target"
[[ $(open "$target") == "$(printf 'open\n%s' "$(cygpath -aw "$target")")" ]]
url='https://example.test/?q=a%20b&x=$value;[test]'
[[ $(open "$url") == "$(printf 'open\n%s' "$url")" ]]
if open >/dev/null 2>&1; then exit 1; fi
if ips --unknown >/dev/null 2>&1; then exit 1; fi
if port-owner 0 >/dev/null 2>&1; then exit 1; fi
if kill-port 123 --invalid >/dev/null 2>&1; then exit 1; fi
if trash / >/dev/null 2>&1; then exit 1; fi
if trash /. >/dev/null 2>&1; then exit 1; fi
if trash "$HOME" >/dev/null 2>&1; then exit 1; fi
if open-files "$target" >/dev/null 2>&1; then exit 1; fi
[[ $(ips --all) == "$(printf 'ips\n--all')" ]]

# Docker must receive the container path without MSYS rewriting it.
docker() {
    [[ ${MSYS_NO_PATHCONV:-} == 1 ]]
    [[ $* == 'run -it --entrypoint /bin/sh test:image' ]]
}
_docker-select-image() { printf 'test:image\n'; }
df-inspect-using-bash test:image

# Verify the fallback to the Windows py launcher even without Python installed.
mkdir "$test_root/bin"
cat > "$test_root/bin/py" <<'SH'
#!/usr/bin/env bash
[[ $1 == -3 ]] || exit 1
case "${3:-}" in
    *sys.version_info.major*) exit 0 ;;
    *os.name*) printf 'nt\r\n' ;;
    *) printf '%s\n' "$PYTHONPATH"; printf '%s\n' "$CONFIG_FILES_DIR" ;;
esac
SH
chmod +x "$test_root/bin/py"
(
    # Hide other Python installations while keeping Git Bash utilities.
    export PATH="$test_root/bin:/usr/bin:/bin"
    python3() { return 1; }
    python() { return 1; }
    unset CONFIG_TOOLS_PYTHON_PATH
    export PYTHONPATH='C:\existing modules'
    source "$repo_root/python/python_tools.sh"
    [[ $CONFIG_TOOLS_PYTHON_EXECUTABLE == py ]]
    expected="$(cygpath -w "$CONFIG_FILES_DIR/python/");C:\existing modules"
    [[ $PYTHONPATH == "$expected" ]]
    [[ $(config-python -c test) == "$(printf '%s\n%s' "$expected" "$(cygpath -aw "$CONFIG_FILES_DIR")")" ]]
)

printf 'PASS: Windows loading, spaced/Unicode paths, argument safety, validation, Docker and Python launcher fallback.\n'
