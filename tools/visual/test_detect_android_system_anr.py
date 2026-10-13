#!/usr/bin/env python3
"""Pixel-only contracts. Synthetic shapes verify detection, not AVD success."""
import unittest
from PIL import Image, ImageDraw
from detect_android_system_anr import is_system_anr_sheet


class SystemAnrSheetContract(unittest.TestCase):
    def test_android_35_pale_system_sheet(self):
        im = Image.new("RGB", (720, 1280), (0, 1, 1))
        pen = ImageDraw.Draw(im)
        pen.rounded_rectangle((50, 486, 670, 815), radius=54,
                              fill=(241, 240, 247))
        pen.rectangle((211, 635, 400, 675), fill=(31, 31, 32))
        self.assertTrue(is_system_anr_sheet(im))

    def test_game_without_system_sheet(self):
        self.assertFalse(is_system_anr_sheet(
            Image.new("RGB", (720, 1280), (19, 21, 24))))

    def test_white_splash_not_a_system_sheet(self):
        self.assertFalse(is_system_anr_sheet(
            Image.new("RGB", (720, 1280), (241, 240, 247))))

    def test_unsupported_viewport_never_matches(self):
        self.assertFalse(is_system_anr_sheet(
            Image.new("RGB", (1080, 1920), (241, 240, 247))))


if __name__ == "__main__":
    unittest.main()
