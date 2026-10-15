#!/usr/bin/env python3
"""Generate a wholly synthetic, redistributable D20 fixture for real Android WebGL QA.

No original/private/licensed BlenderKit bytes enter this file. The 20 nodes named
Gold_1..Gold_20 mirror the contract of the owner model but contain triangle icons,
not numbers, intended only to verify actual offscreen GPU rendering on Android.
"""
import argparse
import json
import math
import struct
from pathlib import Path


def vec_unit(v):
    d = math.sqrt(sum(x*x for x in v))
    return tuple(x / d for x in v)


def vec_cross(a, b):
    return (a[1]*b[2]-a[2]*b[1], a[2]*b[0]-a[0]*b[2], a[0]*b[1]-a[1]*b[0])


def vec_dot(a, b):
    return sum(x*y for x, y in zip(a, b))


def vec_sub(a, b):
    return tuple(x-y for x, y in zip(a, b))


def q_from_z(v):
    z = (0, 0, 1)
    d = vec_dot(z, v)
    if d < -0.99999:
        return [1, 0, 0, 0]
    q = list(vec_cross(z, v)) + [1+d]
    return list(vec_unit(q))


def make_glb():
    golden = (1+math.sqrt(5))/2
    v = [vec_unit(t) for t in [(-1,golden,0),(1,golden,0),(-1,-golden,0),(1,-golden,0),(0,-1,golden),(0,1,golden),(0,-1,-golden),(0,1,-golden),(golden,0,-1),(golden,0,1),(-golden,0,-1),(-golden,0,1)]]
    faces = [(0,11,5),(0,5,1),(0,1,7),(0,7,10),(0,10,11),(1,5,9),(5,11,4),(11,10,2),(10,7,6),(7,1,8),(3,9,4),(3,4,2),(3,2,6),(3,6,8),(3,8,9),(4,9,5),(2,4,11),(6,2,10),(8,6,7),(9,8,1)]
    normals = []
    blackpos = []
    blacknorm = []
    for ff in faces:
        a,b,c = (v[i] for i in ff)
        mid = vec_unit([(a[i]+b[i]+c[i])/3 for i in range(3)])
        n = vec_unit(vec_cross(vec_sub(b,a),vec_sub(c,a)))
        if vec_dot(n, mid)<0:
            n = tuple(-x for x in n)
        normals.append(n)
        for p in (a,b,c):
            blackpos.extend(p)
            blacknorm.extend(n)
    goldpos = [-0.18,-0.145,0,0.18,-0.145,0,0.0,0.22,0]
    goldnorm = [0,0,1]*3
    binary = bytearray()
    views=[]
    def append(values,fmt,target):
        while len(binary)%4:binary.append(0)
        off=len(binary)
        binary.extend(struct.pack('<'+fmt*len(values),*values))
        views.append({'buffer':0,'byteOffset':off,'byteLength':len(binary)-off,'target':target})
        return len(views)-1
    pos0=append(blackpos,'f',34962)
    norm0=append(blacknorm,'f',34962)
    idx0=append(list(range(60)),'H',34963)
    pos1=append(goldpos,'f',34962)
    norm1=append(goldnorm,'f',34962)
    idx1=append([0,1,2],'H',34963)
    access=[
        {'bufferView':pos0,'componentType':5126,'count':60,'type':'VEC3'},
        {'bufferView':norm0,'componentType':5126,'count':60,'type':'VEC3'},
        {'bufferView':idx0,'componentType':5123,'count':60,'type':'SCALAR'},
        {'bufferView':pos1,'componentType':5126,'count':3,'type':'VEC3'},
        {'bufferView':norm1,'componentType':5126,'count':3,'type':'VEC3'},
        {'bufferView':idx1,'componentType':5123,'count':3,'type':'SCALAR'}]
    meshes=[
        {'name':'CC0_Synthetic_Black_Triangles','primitives':[{'attributes':{'POSITION':0,'NORMAL':1},'indices':2,'material':0}]},
        {'name':'CC0_Synthetic_Gold_Triangle_Marker','primitives':[{'attributes':{'POSITION':3,'NORMAL':4},'indices':5,'material':1}]}
    ]
    nodes=[{'name':'CC0_Synthetic_Stone','mesh':0}]
    for n in normals:
        nodes.append({'name':'Gold_'+str(len(nodes)),'mesh':1,'translation':[float(x*1.035) for x in n],'rotation':q_from_z(n)})
    gltf={'asset':{'version':'2.0','generator':'AdelDice test fixture, public synthetic, no private GLB'},'scene':0,'scenes':[{'nodes':list(range(21))}],'nodes':nodes,'meshes':meshes,'buffers':[{'byteLength':len(binary)}],'bufferViews':views,'accessors':access,'materials':[{'name':'synthetic_black','pbrMetallicRoughness':{'baseColorFactor':[0.015,0.019,0.024,1.0],'metallicFactor':0.2,'roughnessFactor':0.35}},{'name':'synthetic_gold','pbrMetallicRoughness':{'baseColorFactor':[1,0.7,0.3,1],'metallicFactor':0.7,'roughnessFactor':0.22}}]}
    j=json.dumps(gltf,separators=(',',':')).encode()
    j+=b' '*((-len(j))%4)
    while len(binary)%4:binary.append(0)
    payload=struct.pack('<4sII',b'glTF',2,12+8+len(j)+8+len(binary))
    payload+=struct.pack('<I4s',len(j),b'JSON')+j+struct.pack('<I4s',len(binary),b'BIN\x00')+binary
    assert len(payload)<16000
    return payload

if __name__=='__main__':
    parser=argparse.ArgumentParser()
    parser.add_argument('dest',type=Path)
    args=parser.parse_args()
    args.dest.parent.mkdir(parents=True,exist_ok=True)
    data=make_glb()
    args.dest.write_bytes(data)
    print('PASS_PUBLIC_D20_21_MESH_PARTS_20_FACES',len(data),'bytes')