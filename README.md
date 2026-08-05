# config-files

Personal shell configuration and small command-line utilities for Linux, macOS, and Termux.

The repo is organized as a set of sourceable shell modules plus a few Python helpers. The main entry point is `bashrc.sh`, which loads the platform-specific files first and then the shared cross-platform tools.

## Supported Environments

- macOS: loads `osx/bashrc_osx.sh`
- Linux: loads `linux/bashrc_linux.sh`
- Termux: loads `termux/bashrc_termux.sh`
- Shared tools: loads `cross/bashrc_cross.sh`, `slide_tool/slide_tools.sh`, and `python/python_tools.sh`

Most commands are shell functions and aliases intended for interactive terminal use.

## Install

Set `CONFIG_FILES_DIR` to this repository and source `bashrc.sh` from your shell startup file:

```sh
export CONFIG_FILES_DIR=<path-to-config-files>
source "$CONFIG_FILES_DIR/bashrc.sh"
```

Example:

```sh
export CONFIG_FILES_DIR="$HOME/workspace/scripts/config-files"
source "$CONFIG_FILES_DIR/bashrc.sh"
```

You can also install through [`gil-install`](https://github.com/adrianogil/gil-tools/blob/master/src/python/gil_install.py):

```sh
cd <path-to-config-files>
gil-install -i
```

## Repository Layout

```text
bashrc.sh              Main entry point
cross/                 Shared aliases and functions
linux/                 Linux-specific shell helpers
osx/                   macOS-specific shell helpers
termux/                Android/Termux-specific shell helpers
python/                Python-backed CLI helpers
slide_tool/            Markdown-to-slide helper scripts
install.gil            gil-install metadata
```

## Command Discovery

The fastest way to rediscover commands is `config-fz`:

```sh
config-fz
```

Aliases:

```sh
cf-fz
cz
```

`config-fz` scans shell files for `# config-tools ...` annotations, opens the list in `default-fuzzy-finder`, and runs the selected command. By default, `default-fuzzy-finder` delegates to `fzf`.

Useful examples from the annotated command set:

| Command | Purpose |
| --- | --- |
| `bkp` | Back up a file or directory |
| `bkp-restore` | Restore a backup |
| `bkp-last` | List the most recently backed-up items |
| `cdk` | Fuzzy-select and enter a child directory |
| `cdp` | Fuzzy-select and enter a parent directory |
| `file-info` | Show metadata, hashes, attributes, and timestamps for a file |
| `clipboard-pick` | Select a saved clipboard item and restore it to the clipboard |
| `ips` | Show the first, all, or primary local IPv4 addresses |
| `case-convert` | Convert text between snake, kebab, camel, and Pascal case |
| `duration-human` | Convert seconds to a readable duration and back |
| `open-files` | Show processes using a path or files opened by a selected process |
| `shell-origin` | Locate the files and lines defining shell aliases, functions, and variables |
| `asdf-set-fzf` | Select an installed ASDF tool and version for `.tool-versions` |
| `file-chunk` | Split a file into numbered pieces of a chosen size |
| `file-chunk-merge` | Validate and merge a directory of numbered chunks |
| `file-to-prompt` | Copy one file as a prompt-ready Markdown code block |
| `dir-to-prompt` | Copy a directory of files as prompt-ready Markdown code blocks |
| `file-navigate-fzf` | Browse files/directories interactively and copy the selected file path |
| `code-file-navigate-fzf` | Browse files/directories interactively and open a selection in VS Code |
| `files-organize` | Run the Python file organizer helper |
| `df-inspect-using-bash` | Open a shell in an explicit or interactively selected Docker image |
| `docker-ps` | Select and describe a running Docker container |
| `docker-stop` | Select and stop one or more running Docker containers |
| `docker-run-fzf` | Pick and run a Docker image through `fzf` |
| `myvars` | Inspect environment variables |
| `which-shell` | Print the current shell process |

There are also OS-specific tools for clipboard integration, browser sessions, editor shortcuts, and file opening.

Use `shell-origin` to find where a loaded shell name comes from:

```sh
shell-origin sd
shell-origin case-convert
shell-origin CROSS_CONFIG_FILES_DIR
shell-origin "$CONFIG_FILES_DIR/python/"
shell-origin --all sd
```

By default, platform-specific results are limited to the current platform.
`--all` also shows definitions from other platform directories.

Backup commands accept an explicit target or open `default-fuzzy-finder` when
the target is omitted:

```sh
bkp [target]
bkp-restore [target]
bkp-last [count]
```

`bkp-last` shows the ten latest backup operations by default.

Use `asdf-set-fzf` (or `aff`) to choose from installed ASDF tools and versions:

```sh
aff                         # Select the tool and version
aff nodejs                  # Select the installed Node.js version
aff nodejs 22.14.0          # Set an installed version directly
aff --home nodejs 22.14.0   # Update ~/.tool-versions
aff --parent                # Update the closest parent .tool-versions
```

## Common Aliases

Some aliases are intentionally short because this repo is optimized for interactive use:

| Alias | Expands to |
| --- | --- |
| `rl` | Reload shell configuration |
| `fz` | `fzf` |
| `fto` | `file-to-prompt` |
| `dto` | `dir-to-prompt` |
| `finfo` | `file-info` |
| `z` | `file-navigate-fzf` |
| `cndz` | `code-file-navigate-fzf` |
| `tn` | `tnew` |
| `te` | `tenter` |
| `tl` | `tlist` |
| `x` | `codex` |
| `cdx` | `codex app` |
| `aff` | `asdf-set-fzf` |

## Development Checks

Run the focused shell syntax check after editing shell configuration or
function modules:

```sh
scripts/check-shell-syntax.sh
```

It parses every shared `*.sh` file with both `bash -n` and `zsh -n`. It also
supports shell-specific `*.bash` and `*.zsh` files, checking each only with its
matching parser. If Bash or Zsh is not installed, that parser is reported as
skipped instead of causing an unclear command-not-found failure.

Run the full smoke test after editing shell modules or Python helpers:

```sh
scripts/smoke-test.sh
```

It runs these checks:

```sh
scripts/check-shell-syntax.sh
CONFIG_FILES_DIR="$PWD" bash --noprofile --norc -c 'source bashrc.sh'
CONFIG_FILES_DIR="$PWD" zsh -f -c 'source bashrc.sh'
python3 syntax checks for files under python/
```

The clean Bash and Zsh commands avoid loading unrelated dotfiles, which keeps the result focused on this repo. The Python check compiles source in memory, so it does not create `__pycache__` directories.

## Notes

- `fzf` is expected for fuzzy-selection commands.
- Clipboard commands are platform-specific: macOS uses `pbcopy`/`pbpaste`, Linux uses `xclip`, and Termux uses Android-oriented helpers. `copy-text-to-clipboard` also saves each copied value as `/tmp/<index>.clipboarditem`; use `clipboard-pick` to restore one through `fzf`.
- Some helpers assume optional tools such as `tmux`, `screen`, `code`, `brew`, `docker`, `youtube-dl`, or `ffmpeg`.

## See Also

- [gil-tools](https://github.com/adrianogil/gil-tools)
- [dotfiles](https://github.com/adrianogil/dotfiles)
