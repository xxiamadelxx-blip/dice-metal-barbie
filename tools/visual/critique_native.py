"""Reproducible *smoke* critic for real Godot/Mesa screenshot evidence.

Not a substitute for a visually independent human/reference comparison.
Checks actual PNG pixels; a zero exit code means only measurable regressions
were not found, NOT that premium visual art is accepted.
"""
import json
import sys
from pathlib import Path
from PIL import Image, ImageStat

def pulse_overspill(path):
    """Count visible pulse-color pixels in the safety strip above the HUD."""
    im = Image.open(path).convert("RGB")
    return sum(1 for r, g, b in im.crop((40, 1000, 680, 1040)).getdata()
               if r > 128 and (r > g * 1.30 and g > b * 1.15
                                or r > g * 1.65 and r > b * 1.30))

def analyze(path):
    im = Image.open(path).convert("RGB")
    w, h = im.size
    if (w, h) != (720, 1280):
        raise AssertionError("Expected native handset-sized 720x1280 capture, got %s" % ((w, h),))
    # Discard HUD and bars: monitor the centered D20 close-up region only.
    roi = im.crop((int(w * .14), int(h * .29), int(w * .86), int(h * .73)))
    pixels = list(roi.getdata())
    lum = sorted((.2126 * r + .7152 * g + .0722 * b) / 255.0 for r, g, b in pixels)
    def pct(p): return round(lum[min(len(lum)-1, int(len(lum)*p))], 4)
    bronze = sum(1 for r, g, b in pixels if r > 95 and r > g * 1.29 and g > b * 1.18)
    clipped = sum(1 for r, g, b in pixels if max(r,g,b) > 246)
    return {"file":str(path),"size":[w,h],"p25":pct(.25),"p50":pct(.50),
            "p75":pct(.75),"p98":pct(.98),"bronze_pixels":bronze,
            "clipped_fraction":round(clipped/len(pixels),4)}

if __name__ == "__main__":
    if len(sys.argv) != 4:
        sys.exit("usage: critique_native.py <D20-detail.png> <staged-gold.png> <staged-crimson.png>")
    try:
        metrics = analyze(Path(sys.argv[1]))
        metrics["gold_pulse_hud_overspill_pixels"] = pulse_overspill(Path(sys.argv[2]))
        metrics["crimson_pulse_hud_overspill_pixels"] = pulse_overspill(Path(sys.argv[3]))
        Path("qa-evidence/native-visual-metrics.json").write_text(json.dumps(metrics,indent=2)+"\n")
        print("Native contrast critic:", json.dumps(metrics))
        # Absolute guardrails, intentionally conservative about random die
        # orientation. Artists still review the original rendered image.
        assert metrics["p75"] >= .12, "Face contrast too dark/flat"
        assert metrics["bronze_pixels"] >= 100, "Engraved bronze not readable"
        assert metrics["clipped_fraction"] < .04, "Blown-out specular highlights"
        assert metrics["gold_pulse_hud_overspill_pixels"] < 50, "Gold aura invades HUD safety region"
        assert metrics["crimson_pulse_hud_overspill_pixels"] < 50, "Crimson aura invades HUD safety region"
        print("PASS native smoke thresholds; ARTISTIC ACCEPTANCE STILL OPEN")
    except Exception as exc:
        print("FAIL native pixel smoke critic:", exc, file=sys.stderr)
        sys.exit(1)
