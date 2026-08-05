import csv
import glob
import json
import os
import re
import shutil
import subprocess
import sys
from pathlib import Path


class PackageOwnerError(Exception):
    pass


def resolve_target(target):
    if os.sep not in target and (os.altsep is None or os.altsep not in target):
        located = shutil.which(target)
        if located is None:
            raise PackageOwnerError("command not found: {}".format(target))
        supplied_path = Path(located)
    else:
        supplied_path = Path(target).expanduser()

    if not supplied_path.exists():
        raise PackageOwnerError("no such file: {}".format(supplied_path))

    return supplied_path.absolute(), supplied_path.resolve()


def add_owner(owners, manager, package, version=""):
    owner = (manager, package.strip(), version.strip())
    if owner[1] and owner not in owners:
        owners.append(owner)


def parts_after(path, marker, count):
    parts = path.parts
    try:
        index = parts.index(marker)
    except ValueError:
        return None
    values = parts[index + 1 : index + 1 + count]
    return values if len(values) == count else None


def detect_path_layouts(path, owners):
    values = parts_after(path, "Cellar", 2)
    if values:
        add_owner(owners, "Homebrew", values[0], values[1])

    values = parts_after(path, "Caskroom", 2)
    if values:
        add_owner(owners, "Homebrew Cask", values[0], values[1])

    values = parts_after(path, "installs", 2)
    if values and ".asdf" in path.parts:
        add_owner(owners, "ASDF", values[0], values[1])
    elif values and "mise" in path.parts:
        add_owner(owners, "Mise", values[0], values[1])

    values = parts_after(path, "versions", 1)
    if values and ".pyenv" in path.parts:
        add_owner(owners, "pyenv", "Python", values[0])
    elif values and ".rbenv" in path.parts:
        add_owner(owners, "rbenv", "Ruby", values[0])

    if ".nvm" in path.parts:
        try:
            node_index = path.parts.index("node", path.parts.index(".nvm") + 1)
        except ValueError:
            node_index = -1
        if node_index >= 0 and node_index + 1 < len(path.parts):
            add_owner(owners, "NVM", "Node.js", path.parts[node_index + 1])

    values = parts_after(path, "candidates", 2)
    if values and ".sdkman" in path.parts:
        add_owner(owners, "SDKMAN", values[0], values[1])

    values = parts_after(path, "venvs", 1)
    if values and "pipx" in path.parts:
        add_owner(owners, "pipx", values[0])

    values = parts_after(path, "tools", 1)
    if values and "uv" in path.parts:
        add_owner(owners, "uv tool", values[0])

    values = parts_after(path, "gems", 1)
    if values:
        match = re.match(r"^(.+)-([0-9][A-Za-z0-9_.-]*)$", values[0])
        if match:
            add_owner(owners, "RubyGems", match.group(1), match.group(2))

    if "node_modules" in path.parts:
        index = path.parts.index("node_modules") + 1
        if index < len(path.parts):
            package = path.parts[index]
            if package.startswith("@") and index + 1 < len(path.parts):
                package += "/" + path.parts[index + 1]
            add_owner(owners, "npm", package)

    if len(path.parts) > 3 and path.parts[1:3] == ("nix", "store"):
        store_name = path.parts[3]
        match = re.match(r"^[^-]+-(.+?)-([0-9][A-Za-z0-9.+_-]*)$", store_name)
        if match:
            add_owner(owners, "Nix", match.group(1), match.group(2))
        else:
            add_owner(owners, "Nix", store_name)


def run_command(arguments):
    if shutil.which(arguments[0]) is None:
        return ""
    try:
        result = subprocess.run(
            arguments,
            stdout=subprocess.PIPE,
            stderr=subprocess.DEVNULL,
            text=True,
            timeout=8,
            check=False,
        )
    except (OSError, subprocess.TimeoutExpired):
        return ""
    return result.stdout.strip() if result.returncode == 0 else ""


def detect_system_packages(paths, owners):
    for path in paths:
        path_text = str(path)

        output = run_command(["dpkg-query", "-S", path_text])
        if output:
            package = output.split(":", 1)[0]
            version = run_command(["dpkg-query", "-W", "-f=${Version}", package])
            add_owner(owners, "dpkg", package, version)

        output = run_command(["rpm", "-qf", "--qf", "%{NAME}\t%{VERSION}-%{RELEASE}", path_text])
        if output and "\t" in output:
            package, version = output.split("\t", 1)
            add_owner(owners, "RPM", package, version)

        output = run_command(["pacman", "-Qo", path_text])
        match = re.search(r" is owned by (\S+) (\S+)$", output)
        if match:
            add_owner(owners, "pacman", match.group(1), match.group(2))

        output = run_command(["apk", "info", "--who-owns", path_text])
        match = re.search(r" is owned by (.+)-([0-9][^ ]*)$", output)
        if match:
            add_owner(owners, "apk", match.group(1), match.group(2))

        output = run_command(["port", "provides", path_text])
        match = re.search(r" is provided by: (\S+)", output)
        if match:
            add_owner(owners, "MacPorts", match.group(1))


def candidate_site_packages(path):
    candidates = []
    parts = path.parts
    if "site-packages" in parts:
        candidates.append(Path(*parts[: parts.index("site-packages") + 1]))

    prefix = path.parent.parent if path.parent.name in ("bin", "Scripts") else None
    if prefix:
        candidates.extend(Path(item) for item in glob.glob(str(prefix / "lib" / "python*" / "site-packages")))
        candidates.append(prefix / "Lib" / "site-packages")
    return [candidate for candidate in candidates if candidate.is_dir()]


def detect_python_distribution(path, owners):
    for site_packages in candidate_site_packages(path):
        for record_path in site_packages.glob("*.dist-info/RECORD"):
            try:
                with record_path.open(encoding="utf-8", errors="replace", newline="") as record:
                    owns_path = any(
                        (site_packages / row[0]).resolve() == path
                        for row in csv.reader(record)
                        if row
                    )
            except OSError:
                continue
            if not owns_path:
                continue

            metadata_path = record_path.parent / "METADATA"
            name = record_path.parent.name.rsplit(".dist-info", 1)[0]
            version = ""
            try:
                for line in metadata_path.read_text(encoding="utf-8", errors="replace").splitlines():
                    if line.startswith("Name: "):
                        name = line[6:]
                    elif line.startswith("Version: "):
                        version = line[9:]
                    if name and version:
                        break
            except OSError:
                pass
            add_owner(owners, "pip", name, version)


def detect_conda(path, owners):
    for parent in path.parents:
        metadata_directory = parent / "conda-meta"
        if not metadata_directory.is_dir():
            continue
        relative_path = str(path.relative_to(parent))
        for metadata_path in metadata_directory.glob("*.json"):
            try:
                metadata = json.loads(metadata_path.read_text(encoding="utf-8"))
            except (OSError, ValueError):
                continue
            if relative_path in metadata.get("files", []):
                add_owner(
                    owners,
                    "Conda",
                    metadata.get("name", metadata_path.stem),
                    metadata.get("version", ""),
                )
                return
        return


def detect_cargo(path, owners):
    cargo_home = Path(os.environ.get("CARGO_HOME", str(Path.home() / ".cargo"))).expanduser()
    if path.parent != (cargo_home / "bin").resolve():
        return
    manifest_path = cargo_home / ".crates.toml"
    try:
        contents = manifest_path.read_text(encoding="utf-8")
    except OSError:
        return

    binary_name = path.name
    if binary_name.endswith(".exe"):
        binary_name = binary_name[:-4]
    pattern = re.compile(r'^"([^ ]+) ([^"]+) \([^)]*\)"\s*=\s*\[(.*)\]$', re.MULTILINE)
    for match in pattern.finditer(contents):
        binaries = re.findall(r'"([^"]+)"', match.group(3))
        if binary_name in binaries or binary_name + ".exe" in binaries:
            add_owner(owners, "Cargo", match.group(1), match.group(2))


def find_owners(supplied_path, resolved_path):
    owners = []
    detect_system_packages((supplied_path, resolved_path), owners)
    detect_path_layouts(resolved_path, owners)
    detect_python_distribution(resolved_path, owners)
    detect_conda(resolved_path, owners)
    detect_cargo(resolved_path, owners)
    return owners


def main(arguments):
    if len(arguments) != 1:
        print("Usage: package-owner <file-or-command>", file=sys.stderr)
        return 2

    try:
        supplied_path, resolved_path = resolve_target(arguments[0])
    except PackageOwnerError as error:
        print("package-owner: {}".format(error), file=sys.stderr)
        return 1

    owners = find_owners(supplied_path, resolved_path)
    print("Target: {}".format(arguments[0]))
    print("Path: {}".format(resolved_path))
    if not owners:
        print("Owner: not found (the file may have been installed manually)")
        return 1

    for manager, package, version in owners:
        suffix = " {}".format(version) if version else ""
        print("Owner: {} — {}{}".format(manager, package, suffix))
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
