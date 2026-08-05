import re
import sys


STYLES = {"snake", "kebab", "camel", "pascal"}


def split_words(value):
    value = re.sub(r"([A-Z]+)([A-Z][a-z])", r"\1 \2", value)
    value = re.sub(r"([a-z0-9])([A-Z])", r"\1 \2", value)
    value = re.sub(r"[^A-Za-z0-9]+", " ", value)
    return [word.lower() for word in value.split()]


def convert_case(value, style):
    words = split_words(value)
    if not words:
        raise ValueError("text does not contain any letters or numbers")

    if style == "snake":
        return "_".join(words)
    if style == "kebab":
        return "-".join(words)
    if style == "camel":
        return words[0] + "".join(word.capitalize() for word in words[1:])
    return "".join(word.capitalize() for word in words)


def main(argv):
    if len(argv) < 2 or argv[1] not in STYLES:
        print(
            "Usage: case-convert <snake|kebab|camel|pascal> [text...]",
            file=sys.stderr,
        )
        return 2

    if len(argv) > 2:
        value = " ".join(argv[2:])
    elif not sys.stdin.isatty():
        value = sys.stdin.read()
    else:
        print("case-convert: provide text as arguments or standard input", file=sys.stderr)
        return 2

    try:
        result = convert_case(value, argv[1])
    except ValueError as error:
        print(f"case-convert: {error}", file=sys.stderr)
        return 2

    print(result)
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv))
