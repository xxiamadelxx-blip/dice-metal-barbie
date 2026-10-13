"""Offline D20 material A/B from an AI-produced image. NOT an AI inference engine.
Only glTF baseColor image is replaced. Numbered geometry, bronze and all
original PBR Normal / roughness stay bit-for-bit unchanged.
"""
import argparse, hashlib, io, json, struct
from pathlib import Path
import numpy as np
from PIL import Image

def read_glb(path):
    raw=Path(path).read_bytes()
    magic,version,length=struct.unpack_from("<4sII",raw)
    assert magic==b"glTF" and version==2 and length==len(raw)
    chunks=[];offset=12
    while offset<len(raw):
        size,kind=struct.unpack_from("<I4s",raw,offset)
        offset+=8
        chunks.append((kind,raw[offset:offset+size]))
        offset+=size
    assert len(chunks)==2 and chunks[0][0]==b"JSON" and chunks[1][0]==(b"BIN"+bytes([0]))
    return json.loads(chunks[0][1]),chunks[1][1]

def write_glb(scene,data):
    def aligned(data,padding):return data+padding*((-len(data))%4)
    j=aligned(json.dumps(scene,ensure_ascii=False,separators=(",",":")).encode(),b" ")
    b=aligned(data,bytes([0]))
    size=12+8+len(j)+8+len(b)
    return (struct.pack("<4sII",b"glTF",2,size)+struct.pack("<I4s",len(j),b"JSON")
            +j+struct.pack("<I4s",len(b),(b"BIN"+bytes([0])))+b)

def run(source,ai_source,out,report):
    scene,original=read_glb(source)
    assert len(original)<40000000
    layers=[(i,m) for i,m in enumerate(scene["materials"])
       if m.get("normalTexture") and m.get("pbrMetallicRoughness",{}).get("baseColorTexture")]
    assert len(layers)==1, "Expected exact canonical D20 authored PBR stone"
    idx,mat=layers[0]
    tid=mat["pbrMetallicRoughness"]["baseColorTexture"]["index"]
    old_mesh=json.dumps(scene["meshes"],sort_keys=True)
    old_access=json.dumps(scene["accessors"],sort_keys=True)
    old_material=json.dumps(mat,sort_keys=True)
    source_img=Image.open(ai_source).convert("RGB")
    assert 64<=source_img.width<=4096 and 64<=source_img.height<=4096
    pixels=np.asarray(source_img.resize((1024,1024),Image.Resampling.LANCZOS),
                      dtype=np.float32)/255.0
    # Artistic color transform only; NO fake AI-derived normal/roughness/AO.
    toned=np.uint8(np.rint(255*np.clip(pixels**0.65*0.87,0,0.54)))
    image=Image.fromarray(toned,"RGB")
    buffer=io.BytesIO();image.save(buffer,format="PNG",optimize=True)
    new_image_data=buffer.getvalue()
    at=(len(original)+3)&~3
    combined=original+bytes(at-len(original))+new_image_data
    scene["bufferViews"].append({"buffer":0,"byteOffset":at,
                                  "byteLength":len(new_image_data)})
    view=len(scene["bufferViews"])-1
    scene["images"].append({"name":"D20_AI_COLOR_EXPERIMENT_NOT_FULL_PBR",
        "mimeType":"image/png","bufferView":view})
    image_index=len(scene["images"])-1
    scene["textures"][tid]["source"]=image_index
    scene["buffers"][0]["byteLength"]=len(combined)
    assert json.dumps(scene["meshes"],sort_keys=True)==old_mesh
    assert json.dumps(scene["accessors"],sort_keys=True)==old_access
    assert json.dumps(scene["materials"][idx],sort_keys=True)==old_material
    target=Path(out);target.parent.mkdir(parents=True,exist_ok=True)
    target.write_bytes(write_glb(scene,combined))
    reopened,data=read_glb(target)
    assert reopened["textures"][tid]["source"]==image_index
    bv=reopened["bufferViews"][view]
    assert data[bv["byteOffset"]:bv["byteOffset"]+bv["byteLength"]]==new_image_data
    result={
        "original_glb_sha256":hashlib.sha256(Path(source).read_bytes()).hexdigest(),
        "experimental_glb_sha256":hashlib.sha256(target.read_bytes()).hexdigest(),
        "geometry_unchanged":True,"accessors_and_number_map_unchanged":True,
        "bronze_normal_roughness_unchanged":True,
        "experimental_AI_basecolor_only":True,"AI_generated_complete_PBR":False,
        "Godot_visual_acceptance":"NOT_VERIFIED",
        "Android_default_changed":False,"source_image_pixels":list(source_img.size),
        "new_image_resolution":1024,"new_color_mean":round(float(toned.mean()),2),
        "new_unique_colors":int(len(np.unique(toned.reshape((-1,3)),axis=0)))}
    Path(report).write_text(json.dumps(result,indent=2,ensure_ascii=False)+chr(10))
    print("PASS_D20_AI_IMAGE_TO_EXISTING_GLTF "+json.dumps(result))

if __name__=="__main__":
    ap=argparse.ArgumentParser()
    ap.add_argument("--source-glb",required=True)
    ap.add_argument("--image",required=True)
    ap.add_argument("--out-glb",required=True)
    ap.add_argument("--report",required=True)
    a=ap.parse_args()
    run(a.source_glb,a.image,a.out_glb,a.report)
