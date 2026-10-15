#!/usr/bin/env python3
"""User-reference-only Fendi look 053 3D reconstruction proof of concept.
Not an accepted likeness: preserve raw failures for later visual review.
"""
from __future__ import annotations
import json, os, shutil, sys, traceback
from pathlib import Path
from PIL import Image, ImageOps
from gradio_client import Client, handle_file

ROOT = Path("build/fendi-ss23")
ROOT.mkdir(parents=True, exist_ok=True)
SOURCE = ROOT / "reference.jpg"
CUTOUT = ROOT / "isolated.png"
LOG = ROOT / "generation.json"

state = {"status": "NOT_VERIFIED", "source": str(SOURCE), "space": "stabilityai/stable-fast-3d"}
try:
    from rembg import new_session, remove
    im = Image.open(SOURCE).convert("RGB")
    # Single figure dominates the center. Crop neighboring runway walkers.
    crop = im.crop((int(im.width * .22), int(im.height * .015), int(im.width * .82), int(im.height * .96)))
    cropped = remove(crop, session=new_session("u2net_human_seg"))
    cropped = cropped.convert("RGBA")
    bbox = cropped.getchannel("A").getbbox()
    if not bbox:
        raise RuntimeError("No alpha segmentation foreground")
    cropped = cropped.crop(bbox)
    # Respect aspect ratio, never stretch the body or face.
    square = Image.new("RGBA", (768, 768), (0, 0, 0, 0))
    thumb = ImageOps.contain(cropped, (695, 695), Image.Resampling.LANCZOS)
    square.alpha_composite(thumb, ((768 - thumb.width)//2, (768-thumb.height)//2))
    square.save(CUTOUT)
    state.update({"input_size": list(im.size), "crop_size": list(crop.size),
                  "alpha_bbox": bbox, "isolated_image": str(CUTOUT)})
    client = Client("stabilityai/stable-fast-3d")
    print("AVAILABLE ENDPOINTS BEGIN",flush=True)
    client.view_api(all_endpoints=True, print_info=True)
    print("AVAILABLE ENDPOINTS END",flush=True)
    print("ENDPOINT IDs",[(i,getattr(e,"api_name",None)) for i,e in client.endpoints.items()],flush=True)
    # This public demo uses one Gradio event for both processing and inference.
    # On user-uploaded RGBA images the prep State is populated automatically.
    # Calling first with no image state may fail; log exactly why rather than
    # fabricate success.
    print("Requesting real 3D mesh from free ZeroGPU demo",flush=True)
    result = client.predict(
        handle_file(str(CUTOUT)), .85, "None", -1, 1024,
        api_name="/run_button"
    )
    state["result_type"] = str(type(result))
    state["result_summary"] = str(result)[:2000]
    paths = []
    def walk(value):
        if isinstance(value, dict):
            for vv in value.values(): walk(vv)
        elif isinstance(value, (tuple, list)):
            for vv in value: walk(vv)
        elif isinstance(value, str):
            if value.lower().endswith((".glb", ".obj", ".gltf")):
                paths.append(value)
    walk(result)
    if not paths:
        raise RuntimeError("Space returned no glb model (see result_summary)")
    src = Path(paths[0])
    shutil.copy2(src, ROOT / "candidate.glb")
    state["status"] = "GENERATED_NOT_ACCEPTED"
    state["model_bytes"] = (ROOT / "candidate.glb").stat().st_size
except Exception as exc:
    state["status"] = "FAIL"
    state["error"] = str(exc)
    state["traceback"] = traceback.format_exc()[-6000:]
    print(state["traceback"],flush=True)
finally:
    LOG.write_text(json.dumps(state,ensure_ascii=False,indent=2),encoding="utf-8")
    print("GENERATION RECORD",json.dumps({k:v for k,v in state.items() if k != "traceback"},ensure_ascii=False),flush=True)
    # The workflow succeeds even when a provider fails, retaining evidence.
