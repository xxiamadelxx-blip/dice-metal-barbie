#!/usr/bin/env python3
"""M4 asynchronous-display pixel gate regression tests (synthetic unit fixtures).

Real Android screenshots and touched Jolt throws remain mandatory in CI.
"""
import sys
import tempfile
import unittest
from pathlib import Path
from PIL import Image, ImageDraw

sys.path.insert(0, str(Path(__file__).resolve().parent))
from check_pool_editor_pixels import changed_pixels, MIN_CHANGED_PIXELS


class PoolPixelGateTests(unittest.TestCase):
    def test_log_only_frame_is_not_displayed_ui(self):
        with tempfile.TemporaryDirectory() as temp:
            before = Path(temp) / "before.png"
            stale = Path(temp) / "stale.png"
            refreshed = Path(temp) / "refreshed.png"
            im = Image.new("RGB", (720, 1280), (22, 24, 30))
            im.save(before)
            im.save(stale)  # ADB captured old framebuffer after Godot log event
            actual = im.copy()
            ImageDraw.Draw(actual).rectangle((290, 450, 340, 510), fill=(232, 208, 176))
            actual.save(refreshed)
            self.assertEqual(changed_pixels(before, stale), 0)
            self.assertGreater(changed_pixels(before, refreshed), MIN_CHANGED_PIXELS)

    def test_changes_outside_editor_roi_not_accepted(self):
        with tempfile.TemporaryDirectory() as temp:
            first = Path(temp) / "a.png"
            second = Path(temp) / "b.png"
            a = Image.new("RGB", (720, 1280), (20, 30, 40))
            a.save(first)
            b = a.copy()
            ImageDraw.Draw(b).rectangle((3, 3, 40, 40), fill=(255, 255, 255))
            b.save(second)
            self.assertEqual(changed_pixels(first, second), 0)

    def test_wrong_resolution_fails_closed(self):
        with tempfile.TemporaryDirectory() as temp:
            first = Path(temp) / "a.png"
            second = Path(temp) / "b.png"
            Image.new("RGB", (720, 1280)).save(first)
            Image.new("RGB", (1080, 2400)).save(second)
            with self.assertRaises(ValueError):
                changed_pixels(first, second)


if __name__ == "__main__":
    unittest.main()
