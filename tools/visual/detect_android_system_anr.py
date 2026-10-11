#!/usr/bin/env python3
"""Read-only geometry detector for an unknown Android 35 system ANR card.
A true result means the game is OCCLUDED and tests must FAIL, never autoclick.
Real failed run #38165752886 Messages sheet was centered x50..670 y486..814.
No OCR, no unsupported app/package identity inference.
"""
import sys
from PIL import Image


def is_system_anr_sheet(image):
    if image.size != (720, 1280):
        return False
    rgb = image.convert("RGB")
    # Original pixels from the actual Messages ANR failure, not generated art:
    # [(80,535),(650,535),(80,625),(650,775)]=(241,240,247)
    for x, y in ((80, 535), (650, 535), (80, 625), (650, 775)):
        r, g, b = rgb.getpixel((x, y))
        if not (230 <= r <= 250 and 230 <= g <= 250 and 233 <= b <= 255):
            return False
    if max(rgb.getpixel((25, 450))) > 100:
        return False
    if max(rgb.getpixel((25, 700))) > 100:
        return False
    # Reject splash/blank uniformly light screens; a real card has a
    # darker interior action-label zone and dark exterior behind the sheet.
    if max(rgb.getpixel((250, 650))) > 135:
        return False
    return True


if __name__ == "__main__":
    if is_system_anr_sheet(Image.open(sys.argv[1])):
        print("SYSTEM_ANR_SHEET")
