import json
import os
import sys
import time
from datetime import datetime
from pathlib import Path


HISTORY_FILENAME = ".history.jsonl"


def history_path(backup_root):
    return backup_root / HISTORY_FILENAME


def resolved_text(value):
    return str(Path(value).expanduser().resolve(strict=False))


def record_backup(arguments):
    if len(arguments) != 5:
        print(
            "Usage: backup_history.py record <root> <target> <snapshot> "
            "<stored> <type>",
            file=sys.stderr,
        )
        return 2

    root_value, target, snapshot, stored, target_type = arguments
    backup_root = Path(root_value)
    backup_root.mkdir(parents=True, exist_ok=True)
    now = datetime.now().astimezone()
    record = {
        "epoch_ns": time.time_ns(),
        "timestamp": now.isoformat(timespec="seconds"),
        "type": target_type,
        "target": resolved_text(target),
        "snapshot": resolved_text(snapshot),
        "stored": resolved_text(stored),
    }
    encoded = (json.dumps(record, ensure_ascii=False) + "\n").encode("utf-8")

    descriptor = os.open(
        history_path(backup_root),
        os.O_WRONLY | os.O_CREAT | os.O_APPEND,
        0o600,
    )
    try:
        remaining = memoryview(encoded)
        while remaining:
            written = os.write(descriptor, remaining)
            remaining = remaining[written:]
    finally:
        os.close(descriptor)
    return 0


def read_history(backup_root):
    records = []
    path = history_path(backup_root)
    if not path.is_file():
        return records

    try:
        lines = path.read_text(encoding="utf-8").splitlines()
    except OSError:
        return records

    for line in lines:
        try:
            record = json.loads(line)
            if (
                isinstance(record, dict)
                and isinstance(record.get("epoch_ns"), (int, float))
                and isinstance(record.get("timestamp"), str)
                and isinstance(record.get("target"), str)
            ):
                records.append(record)
        except (json.JSONDecodeError, TypeError):
            continue
    return records


def discover_stored_backups(backup_root):
    records = []
    if not backup_root.is_dir():
        return records

    for path in backup_root.glob("*/*/*/*"):
        try:
            modified_time = path.stat().st_mtime
        except OSError:
            continue
        timestamp = datetime.fromtimestamp(modified_time).astimezone()
        records.append(
            {
                "epoch_ns": int(modified_time * 1_000_000_000),
                "timestamp": timestamp.isoformat(timespec="seconds"),
                "type": "directory" if path.is_dir() else "file",
                "target": f"[stored backup] {path}",
            }
        )
    return records


def list_backups(arguments):
    if len(arguments) != 2 or not arguments[1].isdigit() or int(arguments[1]) < 1:
        print("Usage: bkp-last [count]", file=sys.stderr)
        return 2

    backup_root = Path(arguments[0])
    count = int(arguments[1])
    records = read_history(backup_root)
    if not records:
        records = discover_stored_backups(backup_root)
    records.sort(key=lambda record: record["epoch_ns"], reverse=True)

    if not records:
        print("No backup history found.")
        return 0

    print(f"{'WHEN':25} {'TYPE':9} TARGET")
    for record in records[:count]:
        print(
            f"{record['timestamp']:25} "
            f"{record.get('type', 'unknown'):9} "
            f"{record['target']}"
        )
    return 0


def main(argv):
    if len(argv) < 2:
        print("Usage: backup_history.py <record|list> ...", file=sys.stderr)
        return 2
    try:
        if argv[1] == "record":
            return record_backup(argv[2:])
        if argv[1] == "list":
            return list_backups(argv[2:])
    except OSError as error:
        command_name = "bkp" if argv[1] == "record" else "bkp-last"
        print(f"{command_name}: {error}", file=sys.stderr)
        return 1

    print("Usage: backup_history.py <record|list> ...", file=sys.stderr)
    return 2


if __name__ == "__main__":
    raise SystemExit(main(sys.argv))
