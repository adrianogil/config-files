import re
import sys
from dataclasses import dataclass
from pathlib import Path


ACTIVE_SHARED_DIRECTORIES = {"cross", "python", "slide_tool"}
PLATFORM_DIRECTORIES = {"linux", "osx", "termux"}


@dataclass(frozen=True)
class Match:
    path: Path
    line_number: int
    kind: str
    source: str
    active: bool


def usage():
    return "Usage: shell-origin [--all] <alias|function|variable|path-entry>"


def is_active_file(relative_path, platform):
    if len(relative_path.parts) == 1:
        return True

    top_directory = relative_path.parts[0]
    if top_directory in PLATFORM_DIRECTORIES:
        return top_directory == platform
    return top_directory in ACTIVE_SHARED_DIRECTORIES


def definition_patterns(target):
    variable_target = target[1:] if target.startswith("$") else target
    escaped_target = re.escape(target)
    escaped_variable = re.escape(variable_target)

    patterns = [
        (
            "alias",
            re.compile(
                rf"^\s*alias\s+(?:--\s+)?(['\"]?){escaped_target}\1\s*="
            ),
        ),
        (
            "function",
            re.compile(
                rf"^\s*(?:function\s+{escaped_target}(?:\s*\(\s*\))?"
                rf"|{escaped_target}\s*\(\s*\))\s*(?:\{{|$)"
            ),
        ),
    ]

    if re.fullmatch(r"[A-Za-z_][A-Za-z0-9_]*", variable_target):
        patterns.append(
            (
                "variable",
                re.compile(
                    rf"^\s*(?:(?:export|readonly)\s+|"
                    rf"typeset(?:\s+-\S+)*\s+)?{escaped_variable}\s*="
                ),
            )
        )
        patterns.append(
            (
                "variable export",
                re.compile(rf"^\s*export\s+{escaped_variable}\s*(?:$|#)"),
            )
        )

    return patterns


def path_spellings(target, root):
    spellings = {target}
    root_text = str(root)
    home_text = str(Path.home())

    if target.startswith(root_text):
        suffix = target[len(root_text) :]
        spellings.add(f"$CONFIG_FILES_DIR{suffix}")
        spellings.add(f"${{CONFIG_FILES_DIR}}{suffix}")
    if target.startswith(home_text):
        suffix = target[len(home_text) :]
        spellings.add(f"$HOME{suffix}")
        spellings.add(f"${{HOME}}{suffix}")
        spellings.add(f"~{suffix}")
    return spellings


def scan_file(path, root, target, platform, patterns):
    relative_path = path.relative_to(root)
    active = is_active_file(relative_path, platform)
    matches = []

    try:
        lines = path.read_text(encoding="utf-8").splitlines()
    except (OSError, UnicodeDecodeError):
        return matches

    path_candidates = path_spellings(target, root) if "/" in target else set()

    for line_number, source in enumerate(lines, start=1):
        if not source.strip() or source.lstrip().startswith("#"):
            continue

        for kind, pattern in patterns:
            if pattern.search(source):
                matches.append(Match(path, line_number, kind, source.strip(), active))
                break
        else:
            if path_candidates and "PATH" in source and any(
                candidate in source for candidate in path_candidates
            ):
                matches.append(
                    Match(path, line_number, "PATH entry", source.strip(), active)
                )

    return matches


def scan_repository(root, target, platform):
    patterns = definition_patterns(target)
    matches = []

    for path in sorted(root.rglob("*.sh")):
        if ".git" in path.parts:
            continue
        matches.extend(scan_file(path, root, target, platform, patterns))

    return matches


def print_matches(label, matches):
    if not matches:
        return

    print(f"{label}:")
    for match in matches:
        print(f"  {match.path}:{match.line_number}  [{match.kind}]")
        print(f"    {match.source}")


def main(argv):
    show_all = False
    arguments = argv[1:]
    if arguments[:1] == ["--all"]:
        show_all = True
        arguments = arguments[1:]

    if len(arguments) != 4:
        print(usage(), file=sys.stderr)
        return 2

    target, root_value, platform, runtime_type = arguments
    root = Path(root_value).resolve()
    if not root.is_dir():
        print(f"shell-origin: configuration directory not found: {root}", file=sys.stderr)
        return 1

    matches = scan_repository(root, target, platform)
    active_matches = [match for match in matches if match.active]
    inactive_matches = [match for match in matches if not match.active]

    print(f"Target: {target}")
    print(f"Runtime type: {runtime_type}")

    if active_matches:
        print_matches("Active definitions", active_matches)
    elif matches:
        print("Active definitions: none")
    else:
        print("Definitions: none found under CONFIG_FILES_DIR")

    if show_all:
        print_matches("Other definitions", inactive_matches)
    elif inactive_matches:
        print(
            f"Other definitions: {len(inactive_matches)} hidden; "
            "use shell-origin --all to show them."
        )

    if not matches:
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv))
