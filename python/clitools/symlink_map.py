import errno
import os
import sys
from pathlib import Path


def inspect_symlink(path):
    target = os.readlink(str(path))

    try:
        resolved = path.resolve(strict=True)
        status = "OK"
    except FileNotFoundError:
        resolved = path.resolve(strict=False)
        status = "BROKEN"
    except RuntimeError:
        resolved = "unresolved"
        status = "LOOP"
    except OSError as error:
        if error.errno == errno.ELOOP:
            resolved = "unresolved"
            status = "LOOP"
        else:
            raise

    return status, target, resolved


def map_symlinks(root):
    links = []
    errors = []

    def record_walk_error(error):
        errors.append(str(error))

    for directory, directories, filenames in os.walk(root, onerror=record_walk_error):
        directories.sort()
        filenames.sort()
        current_directory = Path(directory)

        for name in directories + filenames:
            path = current_directory / name

            if not path.is_symlink():
                continue

            try:
                status, target, resolved = inspect_symlink(path)
                links.append((str(path), status, target, str(resolved)))
            except OSError as error:
                errors.append(f"{path}: {error}")

        directories[:] = [
            name for name in directories if not (current_directory / name).is_symlink()
        ]

    return sorted(links), errors


def main(argv):
    if len(argv) > 2:
        print("Usage: symlink-map [directory]", file=sys.stderr)
        return 2

    root = Path(argv[1] if len(argv) == 2 else ".")

    if not root.is_dir():
        print(f"symlink-map: {root}: Not a directory", file=sys.stderr)
        return 1

    links, errors = map_symlinks(root)

    if not links:
        print("No symbolic links found.")
    else:
        for path, status, target, resolved in links:
            print(f"{status}\t{path} -> {target}")
            print(f"\tresolved: {resolved}")

    for error in errors:
        print(f"symlink-map: warning: {error}", file=sys.stderr)

    return 1 if errors else 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv))
