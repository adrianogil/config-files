import re
import sys


PLAIN_SECONDS = re.compile(r"^[0-9]+$")
DURATION_TOKEN = re.compile(
    r"([0-9]+)\s*"
    r"(weeks?|w|days?|d|hours?|hrs?|h|minutes?|mins?|m|seconds?|secs?|s)",
    re.IGNORECASE,
)
UNIT_SECONDS = {
    "w": 7 * 24 * 60 * 60,
    "week": 7 * 24 * 60 * 60,
    "weeks": 7 * 24 * 60 * 60,
    "d": 24 * 60 * 60,
    "day": 24 * 60 * 60,
    "days": 24 * 60 * 60,
    "h": 60 * 60,
    "hr": 60 * 60,
    "hrs": 60 * 60,
    "hour": 60 * 60,
    "hours": 60 * 60,
    "m": 60,
    "min": 60,
    "mins": 60,
    "minute": 60,
    "minutes": 60,
    "s": 1,
    "sec": 1,
    "secs": 1,
    "second": 1,
    "seconds": 1,
}
OUTPUT_UNITS = (
    ("w", UNIT_SECONDS["w"]),
    ("d", UNIT_SECONDS["d"]),
    ("h", UNIT_SECONDS["h"]),
    ("m", UNIT_SECONDS["m"]),
    ("s", UNIT_SECONDS["s"]),
)


def format_seconds(total_seconds):
    if total_seconds == 0:
        return "0s"

    parts = []
    remaining = total_seconds
    for label, unit_seconds in OUTPUT_UNITS:
        value, remaining = divmod(remaining, unit_seconds)
        if value:
            parts.append(f"{value}{label}")
    return " ".join(parts)


def parse_duration(value):
    total_seconds = 0
    position = 0
    matched = False

    for match in DURATION_TOKEN.finditer(value):
        if value[position : match.start()].strip():
            raise ValueError(f"invalid duration near: {value[position:match.start()].strip()}")

        amount = int(match.group(1))
        unit = match.group(2).lower()
        total_seconds += amount * UNIT_SECONDS[unit]
        position = match.end()
        matched = True

    if not matched:
        raise ValueError("duration must contain a number followed by a unit")
    if value[position:].strip():
        raise ValueError(f"invalid duration near: {value[position:].strip()}")
    return total_seconds


def main(argv):
    if len(argv) > 1:
        value = " ".join(argv[1:]).strip()
    elif not sys.stdin.isatty():
        value = sys.stdin.read().strip()
    else:
        value = ""

    if not value:
        print("Usage: duration-human <seconds|duration>", file=sys.stderr)
        return 2

    try:
        if PLAIN_SECONDS.fullmatch(value):
            result = format_seconds(int(value))
        else:
            result = str(parse_duration(value))
    except ValueError as error:
        print(f"duration-human: {error}", file=sys.stderr)
        return 2

    print(result)
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv))
