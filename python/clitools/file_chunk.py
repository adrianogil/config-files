import re
import shutil
import sys
from pathlib import Path


DEFAULT_CHUNK_SIZE = "100M"
BUFFER_SIZE = 1024 * 1024
SIZE_PATTERN = re.compile(r"^([1-9][0-9]*)([KMG]?)$", re.IGNORECASE)
CHUNK_PATTERN = re.compile(r"^(.+)\.chunk\.([0-9]+)$")
SIZE_MULTIPLIERS = {
    "": 1,
    "K": 1024,
    "M": 1024**2,
    "G": 1024**3,
}


class CommandError(Exception):
    exit_code = 1


class UsageError(CommandError):
    exit_code = 2


def parse_size(value):
    match = SIZE_PATTERN.fullmatch(value)
    if not match:
        raise UsageError("chunk size must be a positive integer followed by K, M, or G")
    return int(match.group(1)) * SIZE_MULTIPLIERS[match.group(2).upper()]


def default_chunk_directory(input_path):
    return input_path.with_name(f"{input_path.name}.chunks")


def default_merged_path(chunk_directory):
    if chunk_directory.name.endswith(".chunks"):
        output_name = chunk_directory.name[: -len(".chunks")]
    else:
        output_name = f"{chunk_directory.name}.merged"
    return chunk_directory.parent / output_name


def split_file(input_path, chunk_size, output_directory):
    if not input_path.is_file():
        raise CommandError(f"{input_path}: No such file")
    if output_directory.exists():
        raise CommandError(f"refusing to overwrite existing path: {output_directory}")
    if not output_directory.parent.is_dir():
        raise CommandError(f"output parent does not exist: {output_directory.parent}")

    output_directory.mkdir()
    chunk_count = 0

    try:
        with input_path.open("rb") as source:
            while True:
                initial_data = source.read(min(BUFFER_SIZE, chunk_size))
                if not initial_data:
                    if chunk_count == 0:
                        empty_chunk = output_directory / f"{input_path.name}.chunk.0000"
                        empty_chunk.touch()
                        chunk_count = 1
                    break

                chunk_path = output_directory / (
                    f"{input_path.name}.chunk.{chunk_count:04d}"
                )
                remaining = chunk_size - len(initial_data)

                with chunk_path.open("wb") as chunk:
                    chunk.write(initial_data)
                    while remaining:
                        data = source.read(min(BUFFER_SIZE, remaining))
                        if not data:
                            break
                        chunk.write(data)
                        remaining -= len(data)

                chunk_count += 1
                if remaining:
                    break
    except Exception:
        shutil.rmtree(output_directory, ignore_errors=True)
        raise

    return chunk_count


def find_chunks(chunk_directory):
    records = []
    for path in chunk_directory.iterdir():
        if not path.is_file():
            continue
        match = CHUNK_PATTERN.fullmatch(path.name)
        if match:
            records.append((match.group(1), int(match.group(2)), path))

    if not records:
        raise CommandError(f"no numbered chunk files found in {chunk_directory}")

    base_names = {record[0] for record in records}
    if len(base_names) != 1:
        raise CommandError("chunk directory contains more than one chunk sequence")

    records.sort(key=lambda record: record[1])
    indices = [record[1] for record in records]
    expected_indices = list(range(len(records)))
    if indices != expected_indices:
        raise CommandError("chunk sequence must be contiguous and start at 0000")

    return [record[2] for record in records]


def merge_chunks(chunk_directory, output_path):
    if not chunk_directory.is_dir():
        raise CommandError(f"{chunk_directory}: Not a directory")
    if output_path.exists():
        raise CommandError(f"refusing to overwrite existing path: {output_path}")
    if not output_path.parent.is_dir():
        raise CommandError(f"output parent does not exist: {output_path.parent}")

    chunk_paths = find_chunks(chunk_directory)
    partial_path = output_path.with_name(f".{output_path.name}.partial")
    if partial_path.exists():
        raise CommandError(f"temporary output already exists: {partial_path}")

    try:
        with partial_path.open("xb") as output:
            for chunk_path in chunk_paths:
                with chunk_path.open("rb") as chunk:
                    shutil.copyfileobj(chunk, output, length=BUFFER_SIZE)
        partial_path.replace(output_path)
    except Exception:
        partial_path.unlink(missing_ok=True)
        raise

    return len(chunk_paths)


def split_command(arguments):
    if not 1 <= len(arguments) <= 3:
        raise UsageError("Usage: file-chunk <file> [size] [output-directory]")

    input_path = Path(arguments[0])
    chunk_size = parse_size(arguments[1] if len(arguments) >= 2 else DEFAULT_CHUNK_SIZE)
    output_directory = (
        Path(arguments[2]) if len(arguments) == 3 else default_chunk_directory(input_path)
    )
    count = split_file(input_path, chunk_size, output_directory)
    print(f"Created {count} chunk(s) in {output_directory}")
    return 0


def merge_command(arguments):
    if not 1 <= len(arguments) <= 2:
        raise UsageError("Usage: file-chunk-merge <chunk-directory> [output-file]")

    chunk_directory = Path(arguments[0])
    output_path = (
        Path(arguments[1])
        if len(arguments) == 2
        else default_merged_path(chunk_directory)
    )
    count = merge_chunks(chunk_directory, output_path)
    print(f"Merged {count} chunk(s) into {output_path}")
    return 0


def main(argv):
    if len(argv) < 2 or argv[1] not in {"split", "merge"}:
        print("Usage: file_chunk.py <split|merge> ...", file=sys.stderr)
        return 2

    try:
        if argv[1] == "split":
            return split_command(argv[2:])
        return merge_command(argv[2:])
    except (OSError, CommandError) as error:
        command_name = "file-chunk" if argv[1] == "split" else "file-chunk-merge"
        print(f"{command_name}: {error}", file=sys.stderr)
        return error.exit_code if isinstance(error, CommandError) else 1


if __name__ == "__main__":
    raise SystemExit(main(sys.argv))
