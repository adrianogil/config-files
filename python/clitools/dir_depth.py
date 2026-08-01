import os
import sys
from pathlib import Path


def deepest_directories(root):
    maximum_depth = 0
    deepest_paths = [root]
    errors = []

    def record_walk_error(error):
        errors.append(str(error))

    for directory, directories, _ in os.walk(root, onerror=record_walk_error):
        directories.sort()
        current_directory = Path(directory)

        for name in list(directories):
            path = current_directory / name
            if path.is_symlink():
                directories.remove(name)
                continue

            depth = len(path.relative_to(root).parts)

            if depth > maximum_depth:
                maximum_depth = depth
                deepest_paths = [path]
            elif depth == maximum_depth:
                deepest_paths.append(path)

    return maximum_depth, sorted(deepest_paths), errors


def main(argv):
    if len(argv) > 2:
        print("Usage: dir-depth [directory]", file=sys.stderr)
        return 2

    root = Path(argv[1] if len(argv) == 2 else ".")

    if not root.is_dir():
        print(f"dir-depth: {root}: Not a directory", file=sys.stderr)
        return 1

    maximum_depth, paths, errors = deepest_directories(root)

    print(f"Maximum depth: {maximum_depth}")
    print("Deepest path(s):")
    for path in paths:
        print(f"  {path}")

    for error in errors:
        print(f"dir-depth: warning: {error}", file=sys.stderr)

    return 1 if errors else 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv))
