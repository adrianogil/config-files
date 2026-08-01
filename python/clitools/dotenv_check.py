import re
import sys
from pathlib import Path


VARIABLE_NAME = re.compile(r"^[A-Za-z_][A-Za-z0-9_]*$")
EXPORT_PREFIX = re.compile(r"^export\s+")


def validate_quoted_value(value):
    if not value or value[0] not in "\"'":
        return None

    quote = value[0]
    escaped = False

    for index in range(1, len(value)):
        character = value[index]

        if quote == '"' and escaped:
            escaped = False
            continue

        if quote == '"' and character == "\\":
            escaped = True
            continue

        if character == quote:
            trailing = value[index + 1 :].strip()
            if trailing and not trailing.startswith("#"):
                return "unexpected text after quoted value"
            return None

    return "unterminated quoted value"


def check_dotenv(path):
    errors = []
    definitions = {}

    try:
        lines = path.read_text(encoding="utf-8-sig").splitlines()
    except (OSError, UnicodeError) as error:
        return [], [f"{path}: {error}"]

    for line_number, original_line in enumerate(lines, start=1):
        line = original_line.strip()

        if not line or line.startswith("#"):
            continue

        line = EXPORT_PREFIX.sub("", line, count=1)

        if "=" not in line:
            errors.append((line_number, "missing '=' assignment"))
            continue

        name, value = line.split("=", 1)
        name = name.strip()
        value = value.strip()

        if not VARIABLE_NAME.fullmatch(name):
            errors.append((line_number, f"invalid variable name: {name or '<empty>'}"))
            continue

        if name in definitions:
            errors.append(
                (
                    line_number,
                    f"duplicate variable {name}; first defined on line "
                    f"{definitions[name]}",
                )
            )
        else:
            definitions[name] = line_number

        value_error = validate_quoted_value(value)
        if value_error:
            errors.append((line_number, f"{name}: {value_error}"))

    return sorted(definitions), errors


def main(argv):
    if len(argv) > 2:
        print("Usage: dotenv-check [file]", file=sys.stderr)
        return 2

    path = Path(argv[1] if len(argv) == 2 else ".env")

    if not path.is_file():
        print(f"dotenv-check: {path}: No such file", file=sys.stderr)
        return 1

    definitions, errors = check_dotenv(path)

    if errors:
        for error in errors:
            if isinstance(error, tuple):
                line_number, message = error
                print(f"{path}:{line_number}: {message}", file=sys.stderr)
            else:
                print(f"dotenv-check: {error}", file=sys.stderr)
        return 1

    print(f"OK: {len(definitions)} unique variable definition(s) in {path}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv))
