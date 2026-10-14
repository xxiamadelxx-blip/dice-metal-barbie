#!/usr/bin/env python3
"""Physically illuminated RGBE panoramas for a fixed top-down Godot Mobile camera.

This generator contains no proprietary BlenderKit PBR map or source assets.
Only the studio illumination changes, never GLB geometry, digits, or stone maps.
Usage: python3 tools/visual/m5_overhead_hdr_generator.py OUTPUT_DIRECTORY
"""
import hashlib
import json
import sys
from pathlib import Path
import numpy as np

W, H = 512, 256
ix, iy = np.meshgrid(np.arange(W) + .5, np.arange(H) + .5)
theta = np.pi * iy / H
phi = 2 * np.pi * ix / W
# Equirectangular Godot sky convention: U=atan2(x,-z), Y is the world up axis.
vectors = np.stack([np.sin(theta)*np.sin(phi), np.cos(theta),
                    -np.sin(theta)*np.cos(phi)], axis=-1).astype(np.float32)
variants = {
    "cap_softbox": dict(bg=.12, cards=[((.05,.99,-.10), .095,.32,7.,(.85,.94,1.))]),
    "two_longcards": dict(bg=.13, cards=[
        ((-.24,.965,-.10), .085,.32,10.,(.85,.92,1.)),
        ((.22,.965,-.14), .07,.23,5.5,(1.,.81,.58))]),
    "zenith_brush": dict(bg=.15,cards=[
        ((0.,.987,-.16), .15,.26,6.,(1.,1.,1.)),
        ((-.36,.92,.15), .075,.30,3.5,(.75,.88,1.))])
}

def generate(output):
    output.mkdir(parents=True,exist_ok=True)
    checks={}
    for name, data in variants.items():
        rgb=np.broadcast_to(np.array([.9,1.,1.10],np.float32)*data["bg"],
                            (H,W,3)).copy()
        for direction,width,height,power,color in data["cards"]:
            center=np.array(direction,np.float32)
            center/=np.linalg.norm(center)
            right=np.cross(center,np.array([0.,0.,1.],np.float32))
            right/=np.linalg.norm(right)
            up=np.cross(right,center)
            facing=np.sum(vectors*center[None,None,:],axis=2)
            denom=np.maximum(facing,1e-5)
            horizontal=np.sum(vectors*right[None,None,:],axis=2)/denom
            vertical=np.sum(vectors*up[None,None,:],axis=2)/denom
            mask=np.exp(-((horizontal/width)**6+(vertical/height)**6)*.5)
            mask*=np.clip((denom-.2)*8.,0.,1.)
            rgb+=mask[...,None]*power*np.array(color,np.float32)
        peak=rgb.max(axis=2)
        _,expo=np.frexp(peak)
        scale=np.ldexp(np.ones_like(peak),8-expo)
        rgbe=np.zeros((H,W,4),np.uint8)
        rgbe[...,:3]=np.clip(rgb*scale[...,None],0,255).astype(np.uint8)
        rgbe[...,3]=(expo+128).astype(np.uint8)
        p=output/("m5_overhead_"+name+".hdr")
        with p.open("wb") as f:
            f.write(f"#?RADIANCE\nFORMAT=32-bit_rle_rgbe\n\n-Y {H} +X {W}\n".encode())
            f.write(rgbe.tobytes())
        checks[name]={"sha256":hashlib.sha256(p.read_bytes()).hexdigest(),
                      "bytes":p.stat().st_size,"parameters":data}
    assert checks["cap_softbox"]["sha256"]=="4d4b5adb93dc5785889d505de18d48a77a45ece3a91f60786bf403c1e5dffcdc", "Studio changed from actual tested source"
    (output/"m5_overhead_source_manifest.json").write_text(json.dumps(checks,indent=2)+"\n")
    print("PASS_ORIGINAL_PHYSICAL_HDR_SOURCE_SHA",json.dumps(checks))

if __name__=="__main__":
    if len(sys.argv)!=2:raise SystemExit("Usage: m5_overhead_hdr_generator.py OUTPUT_DIRECTORY")
    generate(Path(sys.argv[1]))
