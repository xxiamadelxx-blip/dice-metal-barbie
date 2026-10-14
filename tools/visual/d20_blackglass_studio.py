#!/usr/bin/env python3
"""Three reproducible, physically angular HDR reflection tests for a black D20.

No stone BaseColor, mesh, inlay or PBR override is touched. Each output is an
RGBE panorama with finite angular softbox cards. This is an isolated lookdev
experiment, NOT a recreation or substitute for the owner's Blendkit material.
"""
import hashlib
import json
from pathlib import Path
import sys
import numpy as np

sys.path.insert(0, str(Path(__file__).resolve().parent))
from d20_hdr_alignment import encode_radiance, decode_radiance
from d20_narrow_studio import PANELS

SPECS = {
    "black40_lowfill": {"width": .40, "ambient": .50, "cards": 1.0},
    "black40_specular": {"width": .40, "ambient": .50, "cards": 1.6},
    "black33_specular": {"width": .33, "ambient": .42, "cards": 1.75},
}
WIDTH = 512
HEIGHT = 256

def make_hdr(width_scale, ambient_scale, card_intensity):
    yy,xx = np.mgrid[:HEIGHT,:WIDTH].astype(np.float32)
    theta = (yy+.5)/HEIGHT*np.pi
    phi = (xx+.5)/WIDTH*2*np.pi
    xyz = np.stack([np.sin(theta)*np.cos(phi),
                    np.sin(theta)*np.sin(phi),
                    np.cos(theta)],axis=-1)
    background = (.25+.12*np.maximum(xyz[:,:,2],0.0))*ambient_scale
    rgb = np.stack((background*.91,background,background*1.06),axis=-1).astype(np.float32)
    card_mask = np.zeros((HEIGHT,WIDTH),dtype=np.float32)
    for pos, wx, wy, color in PANELS:
        axis = np.asarray(pos,np.float32)
        axis /= np.linalg.norm(axis)
        right = np.cross(axis,np.array([0,0,1],np.float32))
        right /= np.linalg.norm(right)
        up = np.cross(right,axis)
        facing = np.sum(xyz*axis,axis=-1)
        den = np.maximum(facing,0.0001)
        horizontal = np.abs(np.sum(xyz*right,axis=-1)/den)
        vertical = np.abs(np.sum(xyz*up,axis=-1)/den)
        mask = np.clip(np.minimum((wx*width_scale-horizontal)/.08,
                                  (wy*width_scale-vertical)/.08),0,1)
        mask *= np.clip(facing*10,0,1)
        card_mask=np.maximum(card_mask,mask)
        rgb += card_intensity*mask[:,:,None]*np.asarray(color,np.float32)
    peak = rgb.max(axis=2)
    _, expo = np.frexp(peak)
    payload = np.zeros((HEIGHT,WIDTH,4),np.uint8)
    positive = peak>1e-30
    scale = np.zeros_like(peak)
    scale[positive] = np.ldexp(np.ones_like(peak[positive]),8-expo[positive])
    payload[:,:,:3] = np.clip(rgb*scale[:,:,None],0,255).astype(np.uint8)
    payload[:,:,3] = np.where(positive,expo+128,0).astype(np.uint8)
    # Genuine Blender Z-up -> Godot Y-up panorama coordinate remap.
    u_g = (np.arange(WIDTH)+.5)/WIDTH
    cols = np.mod(np.rint(np.mod(.25-u_g,1)*WIDTH-.5).astype(int),WIDTH)
    assert card_mask.max()>.9, "Light cards must actually occupy the HDR"
    assert float(card_mask.mean())<.3, "Light panels cannot wash the entire panorama"
    return payload[:,cols,:], float(card_mask.mean())

def main(destination):
    destination.mkdir(parents=True,exist_ok=True)
    manifest={}
    for name, settings in SPECS.items():
        pixels,coverage=make_hdr(settings["width"],settings["ambient"],settings["cards"])
        output=destination/("learned_studio_mobile_"+name+".hdr")
        encode_radiance(output,pixels)
        assert np.array_equal(decode_radiance(output),pixels)
        manifest[name]={"parameters":settings,"card_coverage_fraction":round(coverage,5),
                        "sha256":hashlib.sha256(output.read_bytes()).hexdigest(),
                        "file_bytes":output.stat().st_size,
                        "transform":"Blender Z-up -> Godot Y-up correct longitude"}
    (destination/"blackglass-studio-source.json").write_text(json.dumps(manifest,indent=2)+"\n")
    print("PASS_PHYSICAL_BLACKGLASS_HDR_VARIANTS",json.dumps(manifest),flush=True)

if __name__=="__main__":
    if len(sys.argv)!=2:raise SystemExit("Usage: d20_blackglass_studio.py OUT_DIR")
    main(Path(sys.argv[1]))
