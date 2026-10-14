#!/usr/bin/env python3
"""Get *real* CC0 black polished stone PBR maps (not generated mock textures).

Source: https://polyhaven.com/a/chess_set, Riley Queen, CC0.
The black marble chess-piece textures are a COMPETITOR reference material,
not the owner's original BlenderKit 'Procedural Obsidian' (currently 403).
Network: documented public API and only its authorized asset download URLs.
"""
import hashlib, json, os, re, sys, time
from io import BytesIO
from pathlib import Path
from urllib.parse import urlparse
from urllib.request import Request, urlopen
from PIL import Image, ImageStat

ROOT=Path(sys.argv[1] if len(sys.argv)>1 else "build/cc0-black-stone")
ROOT.mkdir(parents=True,exist_ok=True)
USER_AGENT="AdelDice-M5-asset-validation/1.0 (Poly Haven licensed CC0 reference)"
BASE="https://api.polyhaven.com"
ASSET_ID="chess_set"
KEYS={"diff":"pieces_black_diff","normal":"pieces_black_nor_gl",
      "rough":"pieces_black_rough"}
MAX_JSON=1500000
MAX_MAP=18000000

def public_get(url,limit):
    assert url.startswith("https://")
    req=Request(url,headers={"User-Agent":USER_AGENT,"Accept":"*/*"})
    with urlopen(req, timeout=35) as response:
        assert response.status==200,(url,response.status)
        content=response.read(limit+1)
        assert len(content)<=limit,("asset exceeds bounded limit",url,len(content))
        return content

def recursive_candidates(obj,ancestor=()):
    if isinstance(obj,dict):
        if isinstance(obj.get("url"),str):
            yield ("/".join(map(str,ancestor)),obj["url"],obj)
        for k,v in obj.items():
            yield from recursive_candidates(v,ancestor+(k,))
    elif isinstance(obj,list):
        for i,v in enumerate(obj):
            yield from recursive_candidates(v,ancestor+(i,))

def choose(candidates,needle):
    found=[]
    for key,url,meta in candidates:
        low=(key+" "+url).lower()
        path=urlparse(url).path.lower()
        if needle not in low or not path.endswith((".png",".jpg",".jpeg")):
            continue
        if urlparse(url).hostname!="dl.polyhaven.org":
            continue
        scale=1 if re.search(r"(?:/|_|-)1k(?:/|_|-|\\.)",low) else 2 if re.search(r"(?:/|_|-)2k(?:/|_|-|\\.)",low) else 99
        fmt=0 if path.endswith(".png") else 1
        found.append((scale,fmt,len(url),key,url,meta))
    found.sort()
    assert found and found[0][0]<=2,("No small official real asset found",needle,
                                        [(k,u) for k,u,_ in candidates if needle in (k+u).lower()][:12])
    return found[0]

def main():
    source=json.loads(public_get(BASE+"/files/"+ASSET_ID,MAX_JSON))
    info=json.loads(public_get(BASE+"/info/"+ASSET_ID,MAX_JSON))
    candidates=list(recursive_candidates(source))
    print("POLYHAVEN_ASSET_FORMAT",type(source).__name__,"top keys",
          list(source)[:18], "url_count",len(candidates),flush=True)
    index=[]
    contact=Image.new("RGB",(1280,410),(15,16,19))
    from PIL import ImageDraw
    canvas=ImageDraw.Draw(contact)
    for i,(kind,needle) in enumerate(KEYS.items()):
        scale,fmt,_,key,url,source_desc=choose(candidates,needle)
        payload=public_get(url,MAX_MAP)
        im=Image.open(BytesIO(payload)).convert("RGB")
        assert 300<=min(im.size)<=4096,(kind,im.size)
        # The untouched source files are kept as-is; archive retains provenance.
        ext=".png" if urlparse(url).path.lower().endswith(".png") else ".jpg"
        p=ROOT/("real_cc0_"+kind+ext)
        p.write_bytes(payload)
        stats=ImageStat.Stat(im)
        index.append({"map":kind,"api_key_path":key,"url":url,"sha256":hashlib.sha256(payload).hexdigest(),
            "bytes":len(payload),"resolution":list(im.size),"mode":"RGB",
            "mean_rgb":[round(x,2) for x in stats.mean],
            "ext":ext,"source_download_verified":True})
        preview=im.resize((398,360))
        contact.paste(preview,(11+i*425,26))
        canvas.text((14+i*425,4),kind+" genuine Poly Haven "+str(scale)+"K",fill=(250,250,250))
        print("PASS_REAL_CC0_CHANNEL",kind,url,im.size,hashlib.sha256(payload).hexdigest(),flush=True)
    assert len(index)==3
    contact.save(ROOT/"real_three_CC0_maps_contact.png")
    record={"asset_id":ASSET_ID,
      "source_page":"https://polyhaven.com/a/chess_set",
      "license":"CC0 as stated on official asset page https://polyhaven.com/license",
      "material_subject":"BLACK MARBLE CHESS PIECES (NOT OBSIDIAN, NOT BLENDERKIT)",
      "artist":"Riley Queen",
      "source_stone_maps_currently_authentic":True,
      "no_purple_assumed":False,
      "maps":index,"info_asset_keys":list(info)[:25],
      "artist_acceptance":"NOT_VERIFIED",
      "geometry_import":"NOT_DONE"}
    (ROOT/"cc0_material_source_manifest.json").write_text(json.dumps(record,indent=2)+"\n")
    print("PASS_CC0_REAL_BLACK_STONE_PBR_DOWNLOADED",json.dumps({"channels":[x["map"] for x in index]}),flush=True)

if __name__=="__main__":
    main()
