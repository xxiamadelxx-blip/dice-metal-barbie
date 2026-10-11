#!/usr/bin/env python3
"""Synthetic system-popup and non-popup pixel contracts; no OCR."""
import unittest
from PIL import Image, ImageDraw
from detect_android_launcher_anr import launcher_anr_close_button


class LauncherAnrDetectorTests(unittest.TestCase):
    def test_popup_card(self):
        picture = Image.new("RGB", (720, 1280), (17, 20, 25))
        ImageDraw.Draw(picture).rounded_rectangle((50, 488, 670, 811),
            radius=55, fill=(241, 240, 247))
        self.assertEqual(launcher_anr_close_button(picture), (250, 650))

    def test_no_false_click_on_game(self):
        self.assertIsNone(launcher_anr_close_button(Image.new("RGB",
            (720, 1280), (19, 21, 24))))

    def test_no_false_click_on_splash(self):
        self.assertIsNone(launcher_anr_close_button(Image.new("RGB",
            (720, 1280), (241, 240, 247))))

    def test_no_unverified_scaled_click(self):
        self.assertIsNone(launcher_anr_close_button(Image.new("RGB",
            (1080, 1920), (241, 240, 247))))


if __name__ == "__main__":
    unittest.main()
