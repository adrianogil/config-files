import os
import stat
import sys
from collections import defaultdict
from pathlib import Path


BINARY_HEADERS = (
    b"\x7fELF",
    b"MZ",
    b"\xca\xfe\xba\xbe",
    b"\xce\xfa\xed\xfe",
    b"\xcf\xfa\xed\xfe",
    b"\xfe\xed\xfa\xce",
    b"\xfe\xed\xfa\xcf",
)


def has_recognized_executable_header(path):
    with path.open("rb") as source:
        header = source.read(4)

    return header.startswith(b"#!") or any(
        header.startswith(binary_header) for binary_header in BINARY_HEADERS
    )


def audit_permissions(root):
    findings = defaultdict(list)
    errors = []

    def record_walk_error(error):
        errors.append(str(error))

    for directory, directories, filenames in os.walk(root, onerror=record_walk_error):
        directories.sort()
        filenames.sort()

        for name in directories + filenames:
            path = Path(directory) / name

            try:
                file_stat = path.lstat()
            except OSError as error:
                errors.append(f"{path}: {error}")
                continue

            mode = file_stat.st_mode
            mode_text = format(stat.S_IMODE(mode), "04o")

            if stat.S_ISLNK(mode):
                continue

            if mode & stat.S_IWOTH:
                if stat.S_ISREG(mode) or not mode & stat.S_ISVTX:
                    findings["World-writable entries"].append((mode_text, path))

            if stat.S_ISREG(mode) and mode & (stat.S_ISUID | stat.S_ISGID):
                findings["Setuid or setgid files"].append((mode_text, path))

            if stat.S_ISREG(mode) and mode & 0o111:
                try:
                    recognized = has_recognized_executable_header(path)
                except OSError as error:
                    errors.append(f"{path}: {error}")
                    continue

                if not recognized:
                    findings["Executables without a recognized header"].append(
                        (mode_text, path)
                    )

    return findings, errors


def main(argv):
    if len(argv) > 2:
        print("Usage: permissions-audit [directory]", file=sys.stderr)
        return 2

    root = Path(argv[1] if len(argv) == 2 else ".")

    if not root.is_dir():
        print(f"permissions-audit: {root}: Not a directory", file=sys.stderr)
        return 1

    findings, errors = audit_permissions(root)

    if not findings:
        print("No permission issues found.")
    else:
        for heading in sorted(findings):
            print(f"\n== {heading} ==")
            for mode, path in findings[heading]:
                print(f"{mode}  {path}")

    for error in errors:
        print(f"permissions-audit: warning: {error}", file=sys.stderr)

    finding_count = sum(len(entries) for entries in findings.values())
    if finding_count:
        print(f"\nFound {finding_count} permission issue(s).", file=sys.stderr)

    return 1 if findings or errors else 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv))
