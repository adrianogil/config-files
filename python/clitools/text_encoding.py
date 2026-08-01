import codecs
import shutil
import subprocess
import sys
from pathlib import Path


SAMPLE_SIZE = 64 * 1024
BOMS = (
    (codecs.BOM_UTF32_BE, "UTF-32 BE", "utf-32be"),
    (codecs.BOM_UTF32_LE, "UTF-32 LE", "utf-32le"),
    (codecs.BOM_UTF8, "UTF-8", "utf-8"),
    (codecs.BOM_UTF16_BE, "UTF-16 BE", "utf-16be"),
    (codecs.BOM_UTF16_LE, "UTF-16 LE", "utf-16le"),
)
TEXT_APPLICATION_TYPES = {
    "application/json",
    "application/javascript",
    "application/toml",
    "application/xml",
    "application/x-httpd-php",
    "application/x-sh",
    "application/yaml",
}


def detect_bom(data):
    for marker, label, encoding in BOMS:
        if data.startswith(marker):
            return label, encoding
    return "none", None


def probe_with_file(path, option):
    if not shutil.which("file"):
        return "unavailable"

    completed = subprocess.run(
        ["file", "--brief", option, str(path.resolve())],
        stdout=subprocess.PIPE,
        stderr=subprocess.DEVNULL,
        text=True,
    )

    if completed.returncode != 0:
        return "unavailable"

    return completed.stdout.strip() or "unavailable"


def inferred_encoding(data, bom_encoding):
    if bom_encoding:
        return bom_encoding
    if not data or all(byte < 128 for byte in data):
        return "us-ascii"
    try:
        data.decode("utf-8")
        return "utf-8"
    except UnicodeDecodeError:
        return "unknown"


def is_binary(data, bom_encoding, mime_type):
    if not data or bom_encoding:
        return False
    if mime_type.startswith("text/") or mime_type in TEXT_APPLICATION_TYPES:
        return False
    if b"\x00" in data:
        return True
    try:
        data.decode("utf-8")
        return False
    except UnicodeDecodeError:
        pass

    allowed_controls = {8, 9, 10, 12, 13, 27}
    control_count = sum(
        1 for byte in data if byte < 32 and byte not in allowed_controls
    )
    return control_count / len(data) > 0.10


def main(argv):
    if len(argv) != 2:
        print("Usage: text-encoding <file>", file=sys.stderr)
        return 2

    path = Path(argv[1])

    if not path.is_file():
        print(f"text-encoding: {path}: No such file", file=sys.stderr)
        return 1

    try:
        with path.open("rb") as source:
            data = source.read(SAMPLE_SIZE)
    except OSError as error:
        print(f"text-encoding: {path}: {error}", file=sys.stderr)
        return 1

    bom_label, bom_encoding = detect_bom(data)
    mime_type = probe_with_file(path, "--mime-type")
    file_encoding = probe_with_file(path, "--mime-encoding")
    content_type = "binary" if is_binary(data, bom_encoding, mime_type) else "text"
    encoding = bom_encoding or file_encoding

    if content_type == "binary" and not bom_encoding:
        encoding = "binary"
    elif encoding in {"binary", "unknown-8bit", "unavailable"}:
        encoding = inferred_encoding(data, bom_encoding)

    print(f"Path:     {path}")
    print(f"MIME:     {mime_type}")
    print(f"Encoding: {encoding}")
    print(f"BOM:      {bom_label}")
    print(f"Content:  {content_type}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv))
