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

def d4_apex_bronze_pixels(path):
    """Count actual engraved-gold pixels, outside HUD, on the die macro.

    This is a smoke metric, not OCR or proof of user-legible typography.
    The old skinny-serif D4 gave 733 pixels in this exact same 720p crop,
    which is insufficient for premium engraving.
    """
    image = Image.open(path).convert("RGB")
    if image.size != (720, 1280):
        raise AssertionError("D4 capture dimensions changed")
    rect = image.crop((70, 420, 600, 955))
    return sum(1 for r,g,b in rect.getdata()
               if r > 95 and r > g * 1.29 and g > b * 1.18)

def _luma(rgb):
    r,g,b=rgb
    return .2126*r+.7152*g+.0722*b

def velvet_nap_readability(path):
    """Check black-green fabric is not the old blue concrete-grey.
    These are rendered pixels, not a texture filename smoke test.
    """
    im=Image.open(path).convert("RGB")
    # A die-free section of the actual tabletop, below the four static dice
    # and above the lower Godot dock. Exclude all rails and labels.
    crop=im.crop((315,800,405,920))
    vals=list(crop.getdata())
    n=len(vals)
    means=[round(sum(px[c] for px in vals)/n,2) for c in range(3)]
    lumas=sorted(_luma(p) for p in vals)
    return {"rgb":means,"p10_luma":round(lumas[int(n*.1)],2),
            "p90_luma":round(lumas[int(n*.9)],2),
            "blue_minus_green":round(means[2]-means[1],2)}

def showcase_face_readability(path):
    """Compare stable four-die hero planes with SAME-FRAME felt at 720x1280.
    A launch composition smoke check, NOT OCR or independent art approval."""
    image=Image.open(path).convert("RGB")
    if image.size != (720,1280):
        raise AssertionError("Normal-camera capture changed resolution")
    # Exclusive non-overlapping regions allow the 1.38x collectible previews
    # room while leaving rails and the bottom ControlDock out of the critic.
    rois={"D20":(122,170,327,369),"D12":(386,214,616,430),
          "D6":(114,443,345,659),"D4":(418,549,629,781)}
    felt=sorted(_luma(px) for px in image.crop((326,478,420,630)).getdata())
    reference=felt[len(felt)//2]
    data={"felt_median":round(reference,2),"dice":{}}
    for name,box in rois.items():
        pixels=list(image.crop(box).getdata())
        values=sorted(_luma(px) for px in pixels)
        p75=values[int(.75*(len(values)-1))]
        gold=sum(1 for r,g,b in pixels if r>95 and r>g*1.29 and g>b*1.18)
        # Obsidian must be BLACK, not blue. The old B-R>9 requirement
        # excluded true dark reflective facets even when fully visible.
        values=sorted(_luma((r,g,b)) for r,g,b in pixels
            if _luma((r,g,b))>reference+12.0
            and _luma((r,g,b))<165.0
            and not (r>95 and r>g*1.29 and g>b*1.18))
        stone=len(values)
        variation=(values[int(.85*(stone-1))]-values[int(.15*(stone-1))]) if stone>5 else 0.0
        data["dice"][name]={"p75":round(p75,2),"against_felt":round(p75-reference,2),
                            "bronze_pixels":gold,"stone_visible_pixels":stone,
                            "facet_dynamic_range":round(variation,2)}
    return data

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
    if len(sys.argv) != 6:
        sys.exit("usage: critique_native.py <D20-detail.png> <staged-gold.png> <staged-crimson.png> <actual-D4-detail.png> <idle-normal.png>")
    try:
        metrics = analyze(Path(sys.argv[1]))
        metrics["gold_pulse_hud_overspill_pixels"] = pulse_overspill(Path(sys.argv[2]))
        metrics["crimson_pulse_hud_overspill_pixels"] = pulse_overspill(Path(sys.argv[3]))
        metrics["d4_bronze_glyph_pixels"] = d4_apex_bronze_pixels(Path(sys.argv[4]))
        metrics["normal_camera"] = showcase_face_readability(Path(sys.argv[5]))
        metrics["velvet_nap"] = velvet_nap_readability(Path(sys.argv[5]))
        Path("qa-evidence/native-visual-metrics.json").write_text(json.dumps(metrics,indent=2)+"\n")
        print("Native contrast critic:", json.dumps(metrics))
        # Absolute guardrails, intentionally conservative about random die
        # orientation. Artists still review the original rendered image.
        assert metrics["velvet_nap"]["blue_minus_green"] < -0.5, (
            "Rendered felt is still blue-grey concrete, not black jade velvet")
        assert metrics["velvet_nap"]["p90_luma"] - metrics["velvet_nap"]["p10_luma"] >= 1.8, (
            "Rendered felt textile nap disappeared into a flat uniform plane")
        assert metrics["p75"] >= .12, "Face contrast too dark/flat"
        assert metrics["bronze_pixels"] >= 100, "Engraved bronze not readable"
        assert metrics["clipped_fraction"] < .04, "Blown-out specular highlights"
        assert metrics["gold_pulse_hud_overspill_pixels"] < 50, "Gold aura invades HUD safety region"
        assert metrics["crimson_pulse_hud_overspill_pixels"] < 50, "Crimson aura invades HUD safety region"
        assert metrics["d4_bronze_glyph_pixels"] >= 950, "D4 apex engraved numerals too thin to pass macro pixel smoke"
        min_hero_stone_pixels={"D20":13000,"D12":19000,"D6":14000,"D4":9000}
        for name,entry in metrics["normal_camera"]["dice"].items():
            assert entry["stone_visible_pixels"] >= min_hero_stone_pixels[name], (
                "%s preview too small/hidden at 720x1280 overhead" % name)
            assert entry["against_felt"] >= 10.0, (
                "%s black stone must contrast clearly against true velvet" % name)
            min_facets={"D20":12.0,"D12":10.0,"D6":10.0,"D4":8.0}
            assert entry["facet_dynamic_range"] >= min_facets[name], (
                "%s stone looks uniform and plastic, not genuinely faceted" % name)
            assert entry["bronze_pixels"] >= 30, (
                "%s engraving disappears at normal 14.2 camera" % name)
        print("PASS native smoke thresholds; ARTISTIC ACCEPTANCE STILL OPEN")
    except Exception as exc:
        print("FAIL native pixel smoke critic:", exc, file=sys.stderr)
        sys.exit(1)
