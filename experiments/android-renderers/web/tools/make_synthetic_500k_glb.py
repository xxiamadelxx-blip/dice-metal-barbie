#!/usr/bin/env python3
"""GENERATE ONLY PUBLIC SYNTHETIC REAL 500K triangle glTF fixture.

Distinct actual triangles on ONE icosahedron, no instancing, no licensed maps,
no engraved 20 numbers. For renderer CI functionality ONLY, not premium QA.
"""
import array
import hashlib
import json
import math
import struct
import sys
from pathlib import Path

PHI=(1+math.sqrt(5))/2
VERTS=[
 (-1,PHI,0),(1,PHI,0),(-1,-PHI,0),(1,-PHI,0),
 (0,-1,PHI),(0,1,PHI),(0,-1,-PHI),(0,1,-PHI),
 (PHI,0,-1),(PHI,0,1),(-PHI,0,-1),(-PHI,0,1)
]
FACES=[
 (0,11,5),(0,5,1),(0,1,7),(0,7,10),(0,10,11),
 (1,5,9),(5,11,4),(11,10,2),(10,7,6),(7,1,8),
 (3,9,4),(3,4,2),(3,2,6),(3,6,8),(3,8,9),
 (4,9,5),(2,4,11),(6,2,10),(8,6,7),(9,8,1)
]
def add(a,b): return tuple(x+y for x,y in zip(a,b))
def sub(a,b): return tuple(x-y for x,y in zip(a,b))
def mul(a,t): return tuple(x*t for x in a)
def dot(a,b): return sum(x*y for x,y in zip(a,b))
def cross(a,b):return (a[1]*b[2]-a[2]*b[1],a[2]*b[0]-a[0]*b[2],a[0]*b[1]-a[1]*b[0])
def norm(v):return mul(v,1/math.sqrt(dot(v,v)))
def interp(a,b,c,u,v):return add(a,add(mul(sub(b,a),u),mul(sub(c,a),v)))
def build(output):
    assert sys.byteorder=="little"
    pos=array.array("f")
    tris=0
    def push_triangle(a,b,c):
        nonlocal tris
        for pt in (a,b,c):pos.extend(pt)
        tris+=1
    for face in FACES:
        a,b,c=[norm(VERTS[i]) for i in face]
        if dot(cross(sub(b,a),sub(c,a)),add(add(a,b),c))<0:b,c=c,b
        face_tri=0
        def tri(u,v,w):
            nonlocal face_tri
            # One triangle per 18 real tessellated triangles is poked
            # into THREE sub-triangles, without cracking adjacent edges.
            # 22500 triangles / 18=1250 pokes/face => 25000 triangles/face.
            if face_tri % 18==0:
                mid=mul(add(add(u,v),w),1/3)
                push_triangle(u,v,mid)
                push_triangle(v,w,mid)
                push_triangle(w,u,mid)
            else:
                push_triangle(u,v,w)
            face_tri+=1
        subdiv=150
        for y in range(subdiv):
            for x in range(subdiv-y):
                u,v=x/subdiv,y/subdiv
                n=1/subdiv
                p0=interp(a,b,c,u,v)
                p1=interp(a,b,c,u+n,v)
                p2=interp(a,b,c,u,v+n)
                tri(p0,p1,p2)
                if x+y+1<subdiv:
                    p3=interp(a,b,c,u+n,v+n)
                    tri(p1,p3,p2)
        assert face_tri==22500
    assert tris==500000 and len(pos)==4500000,(tris,len(pos))
    binary=pos.tobytes()
    gltf={
      "asset":{"version":"2.0","generator":"Dice Lab synthetic single-mesh 500k fixture; not owner-selected"},
      "scenes":[{"nodes":[0]}],"scene":0,
      "nodes":[{"name":"SYNTHETIC_500K_NO_LICENSED_MATERIAL","mesh":0}],
      "meshes":[{"name":"SYNTHETIC_TEST_ONLY","primitives":[{"attributes":{"POSITION":0},"material":0,"mode":4}]}],
      "buffers":[{"byteLength":len(binary)}],
      "bufferViews":[{"buffer":0,"byteOffset":0,"byteLength":len(binary),"target":34962}],
      "accessors":[{"bufferView":0,"componentType":5126,"count":len(pos)//3,"type":"VEC3",
                    "min":[-1.0,-1.0,-1.0],"max":[1.0,1.0,1.0]}],
      "materials":[{"name":"SYNTHETIC_NOT_OBSIDIAN","doubleSided":True,
        "pbrMetallicRoughness":{"baseColorFactor":[.03,.04,.045,1.0],
          "metallicFactor":0,"roughnessFactor":.18}}],
    }
    jb=json.dumps(gltf,separators=(",",":")).encode("utf-8")
    jb+=b" "*((-len(jb))%4)
    bn=binary+b"\x00"*((-len(binary))%4)
    total=12+8+len(jb)+8+len(bn)
    output.parent.mkdir(parents=True,exist_ok=True)
    with output.open("wb") as file:
        file.write(struct.pack("<4sII",b"glTF",2,total))
        file.write(struct.pack("<I4s",len(jb),b"JSON"));file.write(jb)
        file.write(struct.pack("<I4s",len(bn),b"BIN\0"));file.write(bn)
    assert output.stat().st_size==total
    print("PASS_SYNTHETIC_UNIQUE_500000_GLTF_TRIANGLES",{"bytes":total,
           "triangles":tris,"source_sha256":hashlib.sha256(output.read_bytes()).hexdigest(),
           "gold_glyphs":0,"owner_selected_material":False})
if __name__=="__main__":
    if len(sys.argv)!=2:raise SystemExit("Usage: python make_synthetic_500k_glb.py OUTPUT.glb")
    build(Path(sys.argv[1]))
