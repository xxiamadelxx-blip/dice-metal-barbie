#!/usr/bin/env python3
"""Only compose ORIGINAL actual Cycles/Godot screenshots. Never synthesize dice pixels."""
import hashlib
import json
import os
import sys
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont, ImageStat

out = Path("build/d20-compare")
source = out / "blender_cycles.png"
godot_original = out / "godot_source.png"
godot_production = out / "godot_production.png"
# Compare the ACTUAL app-target Mobile renderer on Mesa/Lavapipe, never
# pretending it is real hardware. Compatibility originals stay in the ZIP.
inputs = [
    ("BLENDER / CYCLES", "Cycles, canonical GLB", source),
    ("GODOT / MOBILE BASE", "Original GLB / no reflected studio", out / "godot_mobile_source.png"),
    ("GODOT / MOBILE SKY", "Same GLB + authored reflective sky", out / "godot_mobile_studio.png"),
    ("GODOT / MOBILE PROBE", "Same GLB + real emissive-panel probe", out / "godot_mobile_probe.png"),
]
images = []
for head, desc, p in inputs:
    assert p.is_file() and p.stat().st_size > 10000, "MISSING/EMPTY ACTUAL RENDER: " + str(p)
    with Image.open(p) as im:
        assert im.size == (768,768), (p,im.size)
        x = im.convert("RGB")
        # Solid-black or flat-background image should not quietly become PASS.
        stats = ImageStat.Stat(x)
        assert max(stats.stddev) >= 5, "Likely blank/frozen render: " + str(p)
        images.append((head, desc, p, x.copy(), [round(v,2) for v in stats.stddev]))
scale=1
pad=14
top=86
bottom=93
w=len(images)*768 + (len(images)+1)*pad
h=768+top+bottom
sheet=Image.new("RGB", (w,h), (17,20,24))
draw=ImageDraw.Draw(sheet)
font_path="/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf"
font=ImageFont.truetype(font_path,27)
small=ImageFont.truetype(font_path,17)
for i,(name,desc,path,im,std) in enumerate(images):
    x=pad+i*(768+pad)
    draw.text((x+10,10),name,font=font,fill=(240,240,240))
    draw.text((x+10,49),desc,font=small,fill=(170,181,192))
    sheet.paste(im,(x,top))
draw.text((pad,top+768+12),"SAME EXACT GLB / pose / orthographic angle / frame size. Real engine PNG files above.",font=small,fill=(217,220,225))
draw.text((pad,top+768+42),"Light source models and tonemappers differ. NOT identical illumination or on-phone proof.",font=small,fill=(170,181,192))
from PIL import ImageChops
base_img=images[1][3]
studio_img=images[2][3]
changed=ImageChops.difference(base_img, studio_img)
assert changed.getbbox() is not None, "Studio sky has NO actual Godot Mobile pixel effect"
assert ImageChops.difference(images[2][3], images[3][3]).getbbox() is not None, "Reflection probe has NO actual Godot Mobile pixel effect"
# Film / game art judgment cannot be automated by this numeric smoke.
pixel_stats={
 "baseline_rgb_mean":[round(v,2) for v in ImageStat.Stat(base_img).mean],
 "studio_rgb_mean":[round(v,2) for v in ImageStat.Stat(studio_img).mean],
 "studio_vs_baseline_bbox":changed.getbbox(),
}
final=out/"actual_blender_vs_godot.png"
sheet.save(final)
manifest={
 "source_sha":os.environ.get("GITHUB_SHA","unknown"),
 "generator":"REAL Blender Cycles + REAL Godot engine; Pillow composites screenshots only",
 "comparison_limitations":"One exact GLB; Cycles disk lamps versus Godot Mobile source/studio/probe. No physically matched illumination/tonemapper. Godot Mobile on desktop Mesa/Lavapipe is NOT Android handset evidence.",
 "d20_glb_sha256":hashlib.sha256(Path("src/assets/generated/d20_boolean_engraved.glb").read_bytes()).hexdigest(),
 "studio_ab_delta":pixel_stats,
 "other_authentic_capture_sha256":{p.name:hashlib.sha256(p.read_bytes()).hexdigest() for p in [godot_original, godot_production, out/"godot_studio.png", out/"godot_studio_production.png"] if p.is_file()},
 "probe_ab_delta":{"mobile_sky_rgb_mean":[round(v,2) for v in ImageStat.Stat(images[2][3]).mean],"mobile_probe_rgb_mean":[round(v,2) for v in ImageStat.Stat(images[3][3]).mean],"difference_bbox":ImageChops.difference(images[2][3], images[3][3]).getbbox()},
 "panels":[{"name":name,"source_png":p.name,"sha256":hashlib.sha256(p.read_bytes()).hexdigest(),"std_rgb":std} for name,desc,p,im,std in images],
 "montage_sha256":hashlib.sha256(final.read_bytes()).hexdigest()
}
(out/"evidence_manifest.json").write_text(json.dumps(manifest,indent=2)+"\n")
print("PASS REAL BLENDER GODOT COMPARISON",final,len(images),"panels")
print(json.dumps(manifest,indent=2))
