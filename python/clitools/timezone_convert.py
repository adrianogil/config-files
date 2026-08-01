import sys
from datetime import datetime, timezone

try:
    from zoneinfo import ZoneInfo, ZoneInfoNotFoundError
except ImportError:
    ZoneInfo = None

    class ZoneInfoNotFoundError(Exception):
        pass


ZONE_ALIASES = {
    "manaus": "America/Manaus",
    "sp": "America/Sao_Paulo",
    "brt": "America/Sao_Paulo",
    "est": "Etc/GMT+5",
    "usa chicago": "America/Chicago",
    "south korea": "Asia/Seoul",
    "china": "Asia/Shanghai",
}
DATETIME_FORMATS = (
    "%Y-%m-%d %H:%M:%S",
    "%Y-%m-%d %H:%M",
    "%Y-%m-%dT%H:%M:%S",
    "%Y-%m-%dT%H:%M",
)


def resolve_zone(zone_name):
    zone_key = ZONE_ALIASES.get(zone_name.lower(), zone_name)

    try:
        return zone_key, ZoneInfo(zone_key)
    except ZoneInfoNotFoundError:
        raise ValueError(f"unknown time zone: {zone_name}")


def parse_datetime(value):
    for date_format in DATETIME_FORMATS:
        try:
            return datetime.strptime(value, date_format)
        except ValueError:
            pass

    raise ValueError(
        "datetime must use YYYY-MM-DD HH:MM[:SS] or YYYY-MM-DDTHH:MM[:SS]"
    )


def attach_source_zone(naive_datetime, source_zone):
    first = naive_datetime.replace(tzinfo=source_zone, fold=0)
    second = naive_datetime.replace(tzinfo=source_zone, fold=1)

    first_round_trip = (
        first.astimezone(timezone.utc)
        .astimezone(source_zone)
        .replace(tzinfo=None)
    )
    second_round_trip = (
        second.astimezone(timezone.utc)
        .astimezone(source_zone)
        .replace(tzinfo=None)
    )

    if first_round_trip != naive_datetime and second_round_trip != naive_datetime:
        raise ValueError("source datetime does not exist because of a DST transition")

    is_ambiguous = (
        first.utcoffset() != second.utcoffset()
        and first_round_trip == naive_datetime
        and second_round_trip == naive_datetime
    )
    return first, is_ambiguous


def formatted_offset(value):
    offset = value.strftime("%z")
    return f"{offset[:3]}:{offset[3:]}"


def display_datetime(value, zone_key):
    timestamp = value.strftime("%Y-%m-%d %H:%M:%S")
    return f"{timestamp}  {zone_key}  (UTC{formatted_offset(value)})"


def main(argv):
    if len(argv) != 4:
        print("Usage: timezone-convert <datetime> <from-zone> <to-zone>", file=sys.stderr)
        return 2

    if ZoneInfo is None:
        print("timezone-convert: Python 3.9 or newer is required", file=sys.stderr)
        return 127

    try:
        naive_datetime = parse_datetime(argv[1])
        source_key, source_zone = resolve_zone(argv[2])
        target_key, target_zone = resolve_zone(argv[3])
        source_datetime, is_ambiguous = attach_source_zone(
            naive_datetime, source_zone
        )
    except ValueError as error:
        print(f"timezone-convert: {error}", file=sys.stderr)
        return 2

    target_datetime = source_datetime.astimezone(target_zone)

    print(f"From: {display_datetime(source_datetime, source_key)}")
    print(f"To:   {display_datetime(target_datetime, target_key)}")
    if is_ambiguous:
        print("Note: source time is ambiguous; using the first DST occurrence.")

    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv))
