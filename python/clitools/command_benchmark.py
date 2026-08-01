import shlex
import statistics
import subprocess
import sys
import time


def display_command(command):
    return " ".join(shlex.quote(argument) for argument in command)


def benchmark(runs, command):
    durations = []
    failures = 0

    print(f"Command: {display_command(command)}")
    print(f"Runs: {runs}", flush=True)

    for index in range(1, runs + 1):
        start = time.perf_counter()

        try:
            completed = subprocess.run(command)
        except FileNotFoundError:
            print(f"command-benchmark: command not found: {command[0]}", file=sys.stderr)
            return 127
        except PermissionError:
            print(f"command-benchmark: permission denied: {command[0]}", file=sys.stderr)
            return 126

        duration = time.perf_counter() - start
        durations.append(duration)

        if completed.returncode != 0:
            failures += 1

        print(f"Run {index}: {duration:.6f}s (exit {completed.returncode})", flush=True)

    print("\nSummary:")
    print(f"  Minimum: {min(durations):.6f}s")
    print(f"  Average: {statistics.mean(durations):.6f}s")
    print(f"  Median:  {statistics.median(durations):.6f}s")
    print(f"  Maximum: {max(durations):.6f}s")
    print(f"  Total:   {sum(durations):.6f}s")
    print(f"  Failures: {failures}")

    return 1 if failures else 0


def main(argv):
    if len(argv) < 3:
        print("Usage: command-benchmark <runs> <command...>", file=sys.stderr)
        return 2

    try:
        runs = int(argv[1])
    except ValueError:
        print("command-benchmark: runs must be a positive integer", file=sys.stderr)
        return 2

    if runs < 1:
        print("command-benchmark: runs must be a positive integer", file=sys.stderr)
        return 2

    return benchmark(runs, argv[2:])


if __name__ == "__main__":
    raise SystemExit(main(sys.argv))
