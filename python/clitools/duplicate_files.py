import hashlib
import os
import stat
import sys
from collections import defaultdict
from pathlib import Path


CHUNK_SIZE = 1024 * 1024


def file_digest(path):
    digest = hashlib.sha256()

    with path.open("rb") as source:
        while True:
            chunk = source.read(CHUNK_SIZE)
            if not chunk:
                break
            digest.update(chunk)

    return digest.hexdigest()


def find_duplicates(root):
    files_by_size = defaultdict(list)
    errors = []

    def record_walk_error(error):
        errors.append(str(error))

    for directory, directories, filenames in os.walk(root, onerror=record_walk_error):
        directories.sort()
        filenames.sort()

        for filename in filenames:
            path = Path(directory) / filename

            try:
                file_stat = path.lstat()
            except OSError as error:
                errors.append(f"{path}: {error}")
                continue

            if stat.S_ISREG(file_stat.st_mode):
                files_by_size[file_stat.st_size].append(path)

    duplicate_groups = []

    for size, paths in files_by_size.items():
        if len(paths) < 2:
            continue

        files_by_digest = defaultdict(list)

        for path in paths:
            try:
                files_by_digest[file_digest(path)].append(path)
            except OSError as error:
                errors.append(f"{path}: {error}")

        for digest, matching_paths in files_by_digest.items():
            if len(matching_paths) > 1:
                duplicate_groups.append((size, digest, sorted(matching_paths)))

    duplicate_groups.sort(key=lambda group: (-group[0], group[1]))
    return duplicate_groups, errors


def main(argv):
    if len(argv) > 2:
        print("Usage: duplicate-files [directory]", file=sys.stderr)
        return 2

    root = Path(argv[1] if len(argv) == 2 else ".")

    if not root.is_dir():
        print(f"duplicate-files: {root}: Not a directory", file=sys.stderr)
        return 1

    groups, errors = find_duplicates(root)

    if not groups:
        print("No duplicate files found.")
    else:
        duplicate_bytes = 0

        for index, (size, digest, paths) in enumerate(groups, start=1):
            duplicate_bytes += size * (len(paths) - 1)
            print(
                f"\nGroup {index}: {len(paths)} files, {size} bytes each, "
                f"sha256 {digest}"
            )
            for path in paths:
                print(f"  {path}")

        print(f"\nDuplicate bytes beyond one copy per group: {duplicate_bytes}")

    for error in errors:
        print(f"duplicate-files: warning: {error}", file=sys.stderr)

    return 1 if errors else 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv))
