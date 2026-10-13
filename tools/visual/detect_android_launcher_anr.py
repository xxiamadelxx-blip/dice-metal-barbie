#!/usr/bin/env python3
"""Pixel-grounded Android 35 LAUNCHER-ANR dismissal target, NOT Godot errors.

The caller additionally verifies Android ActivityManager actually logged an ANR
in com.google.android.apps.nexuslauncher. Never dismiss a Godot ANR, and never
interpret a drawn game behind this overlay as touch-accessible gameplay.
"""
import sys
from PIL import Image


def launcher_anr_close_button(image):
    if image.size != (720, 1280):
        return None
    rgb = image.convert("RGB")
    # Real failed run 38133903845: a stationary 620x320 pale Android
    # "Pixel Launcher isn't responding" system sheet covers y488..811.
    # These four points avoid text and option icons. No OCR guesswork.
    samples = [(80, 535), (650, 535), (80, 625), (650, 775)]
    for x, y in samples:
        r, g, b = rgb.getpixel((x, y))
        if not (232 <= r <= 251 and 232 <= g <= 250 and 237 <= b <= 255):
            return None
    # Card must be isolated against dim app UI, not a full white splash.
    r, g, b = rgb.getpixel((25, 450))
    if max(r, g, b) > 100:
        return None
    return 250, 650  # actual "Close app" row, NEVER the game stage


if __name__ == "__main__":
    selected = launcher_anr_close_button(Image.open(sys.argv[1]))
    if selected:
        print("%d %d" % selected)
