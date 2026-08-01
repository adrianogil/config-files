import re
import stat
import sys


OCTAL_MODE = re.compile(r"^[0-7]{3,4}$")
SYMBOLIC_TYPES = "-dlcbps"


def parse_symbolic(mode_text):
    if len(mode_text) == 10 and mode_text[0] in SYMBOLIC_TYPES:
        mode_text = mode_text[1:]

    if len(mode_text) != 9:
        raise ValueError("symbolic mode must contain 9 permission characters")

    mode = 0
    read_positions = ((0, stat.S_IRUSR), (3, stat.S_IRGRP), (6, stat.S_IROTH))
    write_positions = ((1, stat.S_IWUSR), (4, stat.S_IWGRP), (7, stat.S_IWOTH))

    for position, bit in read_positions:
        if mode_text[position] == "r":
            mode |= bit
        elif mode_text[position] != "-":
            raise ValueError(f"invalid read permission: {mode_text[position]}")

    for position, bit in write_positions:
        if mode_text[position] == "w":
            mode |= bit
        elif mode_text[position] != "-":
            raise ValueError(f"invalid write permission: {mode_text[position]}")

    execute_fields = (
        (2, stat.S_IXUSR, stat.S_ISUID, "sS"),
        (5, stat.S_IXGRP, stat.S_ISGID, "sS"),
        (8, stat.S_IXOTH, stat.S_ISVTX, "tT"),
    )

    for position, execute_bit, special_bit, special_characters in execute_fields:
        character = mode_text[position]
        if character == "x":
            mode |= execute_bit
        elif character in special_characters:
            mode |= special_bit
            if character.islower():
                mode |= execute_bit
        elif character != "-":
            raise ValueError(f"invalid execute permission: {character}")

    return mode


def parse_mode(mode_text):
    if OCTAL_MODE.fullmatch(mode_text):
        return int(mode_text, 8)

    return parse_symbolic(mode_text)


def symbolic_mode(mode):
    characters = [
        "r" if mode & stat.S_IRUSR else "-",
        "w" if mode & stat.S_IWUSR else "-",
        "x" if mode & stat.S_IXUSR else "-",
        "r" if mode & stat.S_IRGRP else "-",
        "w" if mode & stat.S_IWGRP else "-",
        "x" if mode & stat.S_IXGRP else "-",
        "r" if mode & stat.S_IROTH else "-",
        "w" if mode & stat.S_IWOTH else "-",
        "x" if mode & stat.S_IXOTH else "-",
    ]

    if mode & stat.S_ISUID:
        characters[2] = "s" if mode & stat.S_IXUSR else "S"
    if mode & stat.S_ISGID:
        characters[5] = "s" if mode & stat.S_IXGRP else "S"
    if mode & stat.S_ISVTX:
        characters[8] = "t" if mode & stat.S_IXOTH else "T"

    return "".join(characters)


def permission_names(value):
    names = []
    if value & 4:
        names.append("read")
    if value & 2:
        names.append("write")
    if value & 1:
        names.append("execute")
    return ", ".join(names) if names else "none"


def explain(mode):
    special = []
    if mode & stat.S_ISUID:
        special.append("setuid")
    if mode & stat.S_ISGID:
        special.append("setgid")
    if mode & stat.S_ISVTX:
        special.append("sticky")

    print(f"Octal:    {mode:04o}")
    print(f"Symbolic: {symbolic_mode(mode)}")
    print(f"Owner:    {permission_names((mode >> 6) & 7)}")
    print(f"Group:    {permission_names((mode >> 3) & 7)}")
    print(f"Other:    {permission_names(mode & 7)}")
    print(f"Special:  {', '.join(special) if special else 'none'}")


def main(argv):
    if len(argv) != 2:
        print("Usage: chmod-explain <mode>", file=sys.stderr)
        return 2

    try:
        mode = parse_mode(argv[1])
    except ValueError as error:
        print(f"chmod-explain: {error}", file=sys.stderr)
        return 2

    explain(mode)
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv))
