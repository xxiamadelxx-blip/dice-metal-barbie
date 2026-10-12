#!/usr/bin/env python3
"""Create artist-controlled narrow studio HDR cards for the same independent D20.
Uses same physical lights as tools/blender/learn_codex_d20.py, changing only
their angular sizes; remaps Blender Z-up panorama into Godot Y-up sky.
No AI image generation and no stone-material or geometry changes.
"""
import argparse,json,hashlib
from pathlib import Path
import numpy as np
from d20_hdr_alignment import encode_radiance,decode_radiance

PANELS=[
 ((.21,-.01,.97),.24,.54,(3.8,4.1,4.4)),
 ((.62,-.80,-.04),.27,.52,(2.7,2.2,1.65)),
 ((-.92,0.,-.39),.23,.47,(1.8,2.05,2.45)),
 ((-.46,.60,.65),.18,.35,(1.25,1.35,1.55))
]
def make(w,h,scale):
    yy,xx=np.mgrid[:h,:w].astype(np.float32)
    theta=(yy+.5)/h*np.pi
    phi=(xx+.5)/w*(2*np.pi)
    d=np.stack((np.sin(theta)*np.cos(phi),np.sin(theta)*np.sin(phi),np.cos(theta)),axis=-1)
    base=.25+.12*np.maximum(d[:,:,2],0.)
    rgb=np.stack((base*.91,base,base*1.06),axis=-1).astype(np.float32)
    for pos,width,height,color in PANELS:
        axis=np.asarray(pos,np.float32);axis/=np.linalg.norm(axis)
        right=np.cross(axis,[0,0,1]);right/=np.linalg.norm(right)
        up=np.cross(right,axis)
        facing=np.sum(d*axis,axis=-1)
        den=np.maximum(facing,.0001)
        rx=np.abs(np.sum(d*right,axis=-1)/den)
        ry=np.abs(np.sum(d*up,axis=-1)/den)
        feather=np.clip(np.minimum((width*scale-rx)/.08,(height*scale-ry)/.08),0,1)
        feather*=np.clip(facing*10,0,1)
        rgb+=feather[:,:,None]*np.asarray(color,np.float32)
    peak=rgb.max(axis=2)
    _,expo=np.frexp(peak)
    rgba=np.zeros((h,w,4),np.uint8)
    valid=peak>1e-30
    multiplier=np.zeros_like(peak)
    multiplier[valid]=np.ldexp(np.ones_like(peak[valid]),8-expo[valid])
    rgba[:,:,:3]=np.clip(rgb*multiplier[:,:,None],0,255).astype(np.uint8)
    rgba[:,:,3]=np.where(valid,expo+128,0).astype(np.uint8)
    u_g=(np.arange(w)+.5)/w
    col=np.mod(np.rint(np.mod(.25-u_g,1)*w-.5).astype(int),w)
    return rgba[:,col,:],rgba

def main():
    p=argparse.ArgumentParser()
    p.add_argument("source",type=Path);p.add_argument("destination",type=Path)
    x=p.parse_args();x.destination.mkdir(parents=True,exist_ok=True)
    reference=decode_radiance(x.source);h,w,_=reference.shape
    _,standard=make(w,h,1.0)
    delta=float(np.abs(standard.astype(float)-reference.astype(float)).mean())
    assert delta<3,("Authored studio source disagreement",delta)
    result={}
    for name,factor in [("narrow50",.5),("narrow30",.3)]:
        pixels,_=make(w,h,factor)
        dest=x.destination/f"learned_studio_mobile_{name}.hdr"
        encode_radiance(dest,pixels)
        assert np.array_equal(pixels,decode_radiance(dest))
        result[name]={"angular_width_scale":factor,"sha256":hashlib.sha256(dest.read_bytes()).hexdigest()}
    (x.destination/"studio-narrow-lights.json").write_text(json.dumps({"reference_source_rgbe_delta":delta,"variants":result},indent=2)+"\n")
    print("PASS_AUTHORED_NARROW_STUDIO_CARD_MAPS",json.dumps(result),delta)
if __name__=="__main__":main()
