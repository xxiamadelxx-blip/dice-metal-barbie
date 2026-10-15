#!/usr/bin/env python3
"""Direct TripoSR CPU inference, isolated from broken public Gradio services.

This is a source-controlled, reproducible experiment, never an assertion of
identity fidelity. Saves a real triangulated candidate.glb only after inference.
"""
import json, os, sys, traceback
from pathlib import Path
import numpy as np
from PIL import Image, ImageOps

OUT=Path("build/fendi-ss23")
OUT.mkdir(parents=True,exist_ok=True)
record={"engine":"TripoSR CPU / local Torch / no remote API","status":"NOT_VERIFIED"}
try:
    import torch
    print("CPU torch",torch.__version__,flush=True)
    sys.path.insert(0,"/tmp/fendi-triposr")
    from tsr.system import TSR
    from rembg import new_session, remove
    source=Image.open(OUT/"reference.jpg").convert("RGB")
    crop=source.crop((int(source.width*.22),int(source.height*.015),int(source.width*.82),int(source.height*.96)))
    rgba=remove(crop,session=new_session("u2net_human_seg")).convert("RGBA")
    bbox=rgba.getchannel("A").getbbox()
    if not bbox: raise RuntimeError("Segmentation returned no person")
    person=rgba.crop(bbox)
    square=Image.new("RGBA",(768,768),(0,0,0,0))
    im=ImageOps.contain(person,(700,700),Image.Resampling.LANCZOS)
    square.alpha_composite(im,((768-im.width)//2,(768-im.height)//2))
    square.save(OUT/"isolated.png")
    # TripoSR is trained on 512px, matte translucent regions to medium gray.
    im=ImageOps.contain(person,(452,452),Image.Resampling.LANCZOS)
    tmp=Image.new("RGBA",(512,512),(0,0,0,0))
    tmp.alpha_composite(im,((512-im.width)//2,(512-im.height)//2))
    backdrop=Image.new("RGB",(512,512),(127,127,127))
    backdrop.paste(tmp,mask=tmp.getchannel("A"))
    backdrop.save(OUT/"tripo_input.jpg",quality=95)
    print("Beginning direct CPU model load",flush=True)
    model=TSR.from_pretrained("stabilityai/TripoSR",config_name="config.yaml",weight_name="model.ckpt")
    model.renderer.set_chunk_size(8192)
    model.to("cpu")
    with torch.inference_mode():
        scene_codes=model(backdrop,device="cpu")
        mesh=model.extract_mesh(scene_codes,resolution=192)[0]
    mesh.export(str(OUT/"candidate.glb"))
    record.update({"status":"GENERATED_NOT_ACCEPTED","mesh_bytes":(OUT/"candidate.glb").stat().st_size,
                   "vertices":int(len(mesh.vertices)),"faces":int(len(mesh.faces))})
    print("TRIPOSR real mesh output",record,flush=True)
except Exception as exc:
    record.update({"status":"FAIL","error":str(exc),"traceback":traceback.format_exc()[-7000:]})
    print(record["traceback"],flush=True)
finally:
    (OUT/"cpu_generation.json").write_text(json.dumps(record,indent=2,ensure_ascii=False),encoding="utf-8")
