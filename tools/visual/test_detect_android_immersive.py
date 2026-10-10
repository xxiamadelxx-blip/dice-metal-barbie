"""Unit regression: actual AVD #38093383377 showed blue pill y331..426."""
import sys
import unittest
from pathlib import Path
from PIL import Image,ImageDraw
sys.path.insert(0,str(Path(__file__).parent))
from detect_android_immersive import locate

class TestAndroidImmersive(unittest.TestCase):
    def test_real_dialog_geometry(self):
        screen=Image.new("RGB",(720,1280),(12,13,18))
        pen=ImageDraw.Draw(screen)
        pen.rounded_rectangle((0,0,719,475),radius=52,fill=(238,237,244))
        pen.rounded_rectangle((533,331,672,427),radius=45,fill=(71,93,146))
        x,y=locate(screen)
        self.assertTrue(590<=x<=610)
        self.assertTrue(367<=y<=390)
        self.assertLess(y,427) # Old fixed 605,447 missed the button
    def test_game_without_tutorial(self):
        self.assertIsNone(locate(Image.new("RGB",(720,1280),(23,29,39))))
    def test_dialog_without_button_is_failure(self):
        screen=Image.new("RGB",(720,1280),(12,13,18))
        ImageDraw.Draw(screen).rectangle((0,0,719,475),fill=(238,237,244))
        with self.assertRaisesRegex(RuntimeError,"button not identified"):
            locate(screen)

if __name__=="__main__":
    unittest.main()
