#!/usr/bin/env python3
"""Remap an unchanged Blender HDR for Godot's actual equirect angular conventions.
For Godot sky.glsl U=atan2(dir.x,-dir.z)/tau, V=acos(dir.y)/pi,
Blender panorama U=atan2(dir.y,dir.x)/tau, V=acos(dir.z)/pi.
For Blender->Godot (x,y,z)->(x,z,-y), U_B=(.25-U_G)%1, V_B=V_G.
No image synthesis or alterations to D20 geometry, paint or materials.
"""
from pathlib import Path
import argparse,hashlib,json,re
import numpy as np

def decode_radiance(path):
    buf=Path(path).read_bytes()
    assert buf.startswith(b"#?RADIANCE\n")
    p=buf.index(b"\n\n")+2
    m=re.match(rb"-Y (\d+) \+X (\d+)\n",buf[p:])
    assert m,"Need exact Radiance top-down RGBE"
    h,w=map(int,m.groups());p+=m.end()
    assert 8<=w<=32767 and h>0
    a=np.empty((h,w,4),np.uint8)
    for y in range(h):
        assert buf[p:p+4]==bytes((2,2,w>>8,w&255))
        p+=4
        for ch in range(4):
            x=0
            while x<w:
                n=buf[p];p+=1
                assert n
                if n>128:
                    ct=n-128;a[y,x:x+ct,ch]=buf[p];p+=1
                else:
                    ct=n;a[y,x:x+ct,ch]=np.frombuffer(buf[p:p+ct],np.uint8);p+=ct
                x+=ct
            assert x==w
    assert p==len(buf)
    return a

def encode_radiance(path,a):
    h,w,_=a.shape
    with Path(path).open("wb") as fp:
        fp.write(f"#?RADIANCE\nFORMAT=32-bit_rle_rgbe\n\n-Y {h} +X {w}\n".encode())
        for row in a:
            fp.write(bytes((2,2,w>>8,w&255)))
            for ch in row.T:
                for x in range(0,w,128):
                    chunk=ch[x:x+128];fp.write(bytes((len(chunk),)))
                    fp.write(chunk.tobytes())

def main():
    a=argparse.ArgumentParser()
    a.add_argument("source",type=Path)
    a.add_argument("target",type=Path)
    x=a.parse_args()
    original=decode_radiance(x.source)
    h,w,_=original.shape
    u_g=(np.arange(w)+.5)/w
    col=np.mod(np.rint(np.mod(.25-u_g,1)*w-.5).astype(int),w)
    out=original[:,col,:]
    encode_radiance(x.target,out)
    assert np.array_equal(decode_radiance(x.target),out)
    assert not np.array_equal(out,original)
    rec={"source_sha256":hashlib.sha256(x.source.read_bytes()).hexdigest(),
       "aligned_sha256":hashlib.sha256(x.target.read_bytes()).hexdigest(),
       "mapping":"U_Blender=(0.25-U_Godot) modulo 1; V unchanged",
       "same_exposure_samples":True,"width":w,"height":h}
    x.target.with_suffix(".alignment.json").write_text(json.dumps(rec,indent=2)+"\n")
    print("PASS_TRUE_RADIANCE_HDR_COORDINATE_REMAP",json.dumps(rec))

if __name__=="__main__":main()
