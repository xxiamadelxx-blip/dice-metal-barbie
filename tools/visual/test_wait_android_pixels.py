"""Synthetic retry fixtures; never label these actual emulator evidence."""
import io
from pathlib import Path
import sys
import tempfile
import unittest
from PIL import Image, ImageDraw

sys.path.insert(0, str(Path(__file__).resolve().parent))
from wait_android_pixels import wait_for_pixels
from check_pool_editor_pixels import changed_pixels


def png(changed=False, outside=False, size=(720,1280)):
    im=Image.new('RGB',size,(20,30,40))
    if changed:
        ImageDraw.Draw(im).rectangle((100,150,200,250),fill='white')
    if outside:
        ImageDraw.Draw(im).rectangle((100,700,300,900),fill='white')
    output=io.BytesIO();im.save(output,format='PNG');return output.getvalue()


class DisplayReadinessTests(unittest.TestCase):
    def test_history_keeps_stricter_per_pixel_threshold(self):
        with tempfile.TemporaryDirectory() as folder:
            before=Path(folder)/'before.png';after=Path(folder)/'after.png'
            before.write_bytes(png())
            im=Image.new('RGB',(720,1280),(20,30,40))
            ImageDraw.Draw(im).rectangle((100,150,200,250),fill=(37,47,57))
            im.save(after)
            self.assertGreater(changed_pixels(before,after,(17,106,703,510),16),7500)
            self.assertEqual(changed_pixels(before,after,(17,106,703,510),18),0)

    def test_stale_frames_are_retained_until_real_pixels_arrive(self):
        with tempfile.TemporaryDirectory() as folder:
            before=Path(folder)/'before.png';after=Path(folder)/'after.png'
            before.write_bytes(png())
            sequence=iter([png(),png(),png(changed=True)])
            count=wait_for_pixels(before,after,7500,(17,106,703,510),
                                  interval=0,capture=lambda seconds:next(sequence))
            self.assertGreater(count,7500)
            self.assertEqual((Path(folder)/'after-waiting-01.png').read_bytes(),before.read_bytes())
            self.assertEqual((Path(folder)/'after-waiting-02.png').read_bytes(),before.read_bytes())

    def test_unchanged_or_outside_changes_timeout_instead_of_passing(self):
        for data in [png(),png(outside=True)]:
            with self.subTest(),tempfile.TemporaryDirectory() as folder:
                before=Path(folder)/'before.png';after=Path(folder)/'after.png';before.write_bytes(png())
                with self.assertRaises(TimeoutError):
                    wait_for_pixels(before,after,7500,(17,106,703,510),timeout=.05,
                                    interval=.01,capture=lambda seconds:data)

    def test_wrong_dimensions_fail_closed(self):
        with tempfile.TemporaryDirectory() as folder:
            before=Path(folder)/'before.png';after=Path(folder)/'after.png';before.write_bytes(png())
            with self.assertRaises(ValueError):
                wait_for_pixels(before,after,7500,(17,106,703,510),
                                capture=lambda seconds:png(size=(1080,2400)))


if __name__=='__main__':unittest.main()
