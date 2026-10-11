#!/usr/bin/env python3
"""Strict original-pixel gate for the Android M4 pool editor.

The Godot UI-event log proves a touch reached game logic, but does not prove
the emulator display has submitted a new frame yet. Poll this AFTER the event,
using precisely the same image metric as the full-frame auditor.
"""
import argparse
from pathlib import Path
from PIL import Image, ImageChops

_CROP = (50, 170, 680, 1130)
_SIZE = (720, 1280)
MIN_CHANGED_PIXELS = 75


def changed_pixels(before: Path, after: Path) -> int:
    with Image.open(before) as image:
        a = image.convert("RGB")
    with Image.open(after) as image:
        b = image.convert("RGB")
    if a.size != _SIZE or b.size != _SIZE:
        raise ValueError("Android AVD screenshots must both be 720x1280")
    delta = ImageChops.difference(a.crop(_CROP), b.crop(_CROP)).convert("L")
    return sum(delta.histogram()[17:])


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("before", type=Path)
    parser.add_argument("after", type=Path)
    parser.add_argument("--minimum", type=int, default=MIN_CHANGED_PIXELS)
    args = parser.parse_args()
    count = changed_pixels(args.before, args.after)
    print(f"Original Android editor changed pixels: {count} (must exceed {args.minimum})", flush=True)
    if count <= args.minimum:
        raise SystemExit(1)


if __name__ == "__main__":
    main()
