import os
import sys
from collections import defaultdict
from pathlib import Path


IGNORED_DIRECTORIES = {
    ".git",
    ".hg",
    ".mypy_cache",
    ".pytest_cache",
    ".svn",
    ".tox",
    ".venv",
    "__pycache__",
    "build",
    "coverage",
    "dist",
    "node_modules",
    "target",
    "vendor",
    "venv",
}
LANGUAGES_BY_EXTENSION = {
    ".bash": "Shell",
    ".c": "C",
    ".cc": "C++",
    ".clj": "Clojure",
    ".cljs": "Clojure",
    ".cmake": "CMake",
    ".cpp": "C++",
    ".cs": "C#",
    ".css": "CSS",
    ".dart": "Dart",
    ".ex": "Elixir",
    ".exs": "Elixir",
    ".fish": "Fish",
    ".go": "Go",
    ".h": "C",
    ".hh": "C++",
    ".hpp": "C++",
    ".html": "HTML",
    ".htm": "HTML",
    ".java": "Java",
    ".js": "JavaScript",
    ".jsx": "JavaScript",
    ".json": "JSON",
    ".kt": "Kotlin",
    ".kts": "Kotlin",
    ".lua": "Lua",
    ".m": "Objective-C",
    ".md": "Markdown",
    ".php": "PHP",
    ".pl": "Perl",
    ".pm": "Perl",
    ".ps1": "PowerShell",
    ".py": "Python",
    ".r": "R",
    ".rb": "Ruby",
    ".rs": "Rust",
    ".scala": "Scala",
    ".scss": "SCSS",
    ".sh": "Shell",
    ".sql": "SQL",
    ".swift": "Swift",
    ".toml": "TOML",
    ".ts": "TypeScript",
    ".tsx": "TypeScript",
    ".vue": "Vue",
    ".xml": "XML",
    ".yaml": "YAML",
    ".yml": "YAML",
    ".zsh": "Shell",
}
LANGUAGES_BY_FILENAME = {
    ".bash_profile": "Shell",
    ".bashrc": "Shell",
    ".zprofile": "Shell",
    ".zshrc": "Shell",
    "cmakelists.txt": "CMake",
    "dockerfile": "Dockerfile",
    "gemfile": "Ruby",
    "makefile": "Make",
    "rakefile": "Ruby",
}
SHEBANG_LANGUAGES = {
    "bash": "Shell",
    "dash": "Shell",
    "fish": "Fish",
    "node": "JavaScript",
    "nodejs": "JavaScript",
    "perl": "Perl",
    "php": "PHP",
    "python": "Python",
    "python3": "Python",
    "ruby": "Ruby",
    "sh": "Shell",
    "zsh": "Shell",
}


def language_from_shebang(path):
    try:
        with path.open("rb") as source:
            first_line = source.readline(256)
    except OSError:
        return None

    if not first_line.startswith(b"#!"):
        return None

    shebang = first_line.decode("ascii", errors="ignore").lower()
    for interpreter, language in SHEBANG_LANGUAGES.items():
        if interpreter in shebang:
            return language
    return None


def detect_language(path):
    language = LANGUAGES_BY_FILENAME.get(path.name.lower())
    if language:
        return language

    language = LANGUAGES_BY_EXTENSION.get(path.suffix.lower())
    if language:
        return language

    return language_from_shebang(path)


def count_lines(path):
    lines = 0
    last_byte = None

    with path.open("rb") as source:
        while True:
            chunk = source.read(1024 * 1024)
            if not chunk:
                break
            if b"\x00" in chunk:
                return None
            lines += chunk.count(b"\n")
            last_byte = chunk[-1]

    if last_byte is not None and last_byte != 10:
        lines += 1
    return lines


def collect_stats(root):
    stats = defaultdict(lambda: [0, 0])
    errors = []

    def record_walk_error(error):
        errors.append(str(error))

    for directory, directories, filenames in os.walk(root, onerror=record_walk_error):
        current_directory = Path(directory)
        directories[:] = sorted(
            name
            for name in directories
            if name not in IGNORED_DIRECTORIES
            and not (current_directory / name).is_symlink()
        )

        for filename in sorted(filenames):
            path = current_directory / filename
            if path.is_symlink():
                continue

            language = detect_language(path)
            if not language:
                continue

            try:
                lines = count_lines(path)
            except OSError as error:
                errors.append(f"{path}: {error}")
                continue

            if lines is None:
                continue

            stats[language][0] += 1
            stats[language][1] += lines

    return stats, errors


def main(argv):
    if len(argv) > 2:
        print("Usage: code-stats [directory]", file=sys.stderr)
        return 2

    root = Path(argv[1] if len(argv) == 2 else ".")
    if not root.is_dir():
        print(f"code-stats: {root}: Not a directory", file=sys.stderr)
        return 1

    stats, errors = collect_stats(root)

    if not stats:
        print("No recognized source files found.")
    else:
        rows = sorted(stats.items(), key=lambda item: (-item[1][1], item[0]))
        language_width = max(8, max(len(language) for language in stats))

        print(f"{'Language':<{language_width}}  {'Files':>7}  {'Lines':>10}")
        print(f"{'-' * language_width}  {'-' * 7}  {'-' * 10}")

        total_files = 0
        total_lines = 0
        for language, (files, lines) in rows:
            total_files += files
            total_lines += lines
            print(f"{language:<{language_width}}  {files:>7}  {lines:>10}")

        print(f"{'-' * language_width}  {'-' * 7}  {'-' * 10}")
        print(f"{'TOTAL':<{language_width}}  {total_files:>7}  {total_lines:>10}")

    for error in errors:
        print(f"code-stats: warning: {error}", file=sys.stderr)

    return 1 if errors else 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv))
