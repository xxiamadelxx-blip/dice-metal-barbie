"""Wait for an original ADB frame to satisfy the existing pixel-change gate.

Never repeat the input tap: on a toggle, a second tap can close the drawer.
Synthetic unit fixtures exercise retries; actual Android acceptance is CI-only.
"""
import argparse
from pathlib import Path
import subprocess
import time

from check_pool_editor_pixels import changed_pixels


def adb_capture(seconds):
    return subprocess.run(['adb', 'exec-out', 'screencap', '-p'],
                          capture_output=True, check=True, timeout=seconds).stdout


def wait_for_pixels(before, after, minimum, crop, *, timeout=20, interval=.8,
                    difference_threshold=16, capture=adb_capture):
    if minimum < 0 or timeout <= 0 or interval < 0:
        raise ValueError('Invalid screenshot readiness bounds')
    deadline = time.monotonic() + timeout
    attempts = 0
    count = 0
    after.parent.mkdir(parents=True, exist_ok=True)
    while time.monotonic() < deadline:
        remaining = deadline - time.monotonic()
        if remaining <= 0:
            break
        after.write_bytes(capture(min(10, remaining)))
        attempts += 1
        count = changed_pixels(before, after, crop, difference_threshold)
        print(f'Original Android frame {attempts}: {count} changed pixels; require >{minimum}', flush=True)
        if count > minimum:
            return count
        # Preserve genuine stale frames as evidence, not just the last retry.
        waiting = after.with_name(after.stem + f'-waiting-{attempts:02d}' + after.suffix)
        waiting.write_bytes(after.read_bytes())
        time.sleep(min(interval, max(0, deadline-time.monotonic())))
    raise TimeoutError(f'No displayed Android update in {timeout}s: last pixels={count}, threshold>{minimum}')


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('before', type=Path)
    parser.add_argument('after', type=Path)
    parser.add_argument('--minimum', type=int, required=True)
    parser.add_argument('--crop', type=int, nargs=4, required=True)
    parser.add_argument('--timeout', type=float, default=20)
    parser.add_argument('--difference-threshold', type=int, default=16)
    args = parser.parse_args()
    wait_for_pixels(args.before, args.after, args.minimum, tuple(args.crop), timeout=args.timeout,
                    difference_threshold=args.difference_threshold)


if __name__ == '__main__':
    main()
