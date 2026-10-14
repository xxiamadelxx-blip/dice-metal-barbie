#!/usr/bin/env python3
"""Fetch actual CC0 black marble seamless PBR maps from the publisher page.

Not BlenderKit's exact selected obsidian. Black marble is a visually adjacent,
real download-ready material for honest A/B. Site CC0 licensing and true image
file hashes recorded before any use or transformation.
"""
import hashlib,html,json,re,sys,zipfile
from html.parser import HTMLParser
from io import BytesIO
from pathlib import Path
from urllib.parse import urljoin,urlparse
from urllib.request import Request,urlopen
from PIL import Image,ImageStat

OUT=Path(sys.argv[1] if len(sys.argv)>1 else "build/cc0-nero-marquina")
OUT.mkdir(parents=True,exist_ok=True)
BASE="https://proctexture.com"
INDEX=BASE+"/textures"
AGENT="AdelDice-M5-real-CC0-obsidian-material-alternative/1.0"
MAX_HTML=3000000
MAX_ZIP=42000000

class Anchors(HTMLParser):
    def __init__(self):
        super().__init__()
        self.anchors=[]
        self.anc=None
    def handle_starttag(self,tag,attrs):
        if tag=="a":
            self.anc={"attrs":dict(attrs),"text":""}
    def handle_data(self,data):
        if self.anc is not None:self.anc["text"]+=data
    def handle_endtag(self,tag):
        if tag=="a" and self.anc is not None:
            self.anchors.append(self.anc)
            self.anc=None

def download(url,cap):
    assert urlparse(url).scheme=="https",url
    assert urlparse(url).hostname in ["proctexture.com","www.proctexture.com"],url
    with urlopen(Request(url,headers={"User-Agent":AGENT}),timeout=30) as r:
        assert r.status==200
        data=r.read(cap+1)
        assert len(data)<=cap,(url,len(data),cap)
        return data

def main():
    page=download(INDEX,MAX_HTML).decode("utf-8","replace")
    assert re.search("Nero Marquina",page,re.I), "Published material not found"
    assert "CC0" in page or "cc0" in page,"Publisher CC0 statement not in page"
    # Only choose the 1K ZIP hyperlink inside the exact Nero Marquina card,
    # not a blind site-wide "download" search.
    middle=re.search(r"Nero Marquina.{0,12000}?Download 1K PBR Pack",page,re.S|re.I)
    assert middle, "Nero Marquina download action not found"
    snippet=page[middle.start():middle.end()+450]
    # Parse every anchor in the corresponding local card.
    parse=Anchors()
    parse.feed(snippet)
    links=[a for a in parse.anchors if "Download 1K PBR Pack" in a["text"]]
    if not links:
        # Typically the material name and ZIP are in separate headings; locate
        # the anchor of ZIP using the last href immediately before action label.
        z=re.findall(r'<a[^>]*href=["\']([^"\']+)["\'][^>]*>[^<]*Download 1K PBR Pack',snippet,re.I)
        assert z,("Cannot identify exact Nero ZIP",snippet[-450:])
        href=z[-1]
    else:
        href=links[-1]["attrs"].get("href")
    assert href
    url=urljoin(BASE,html.unescape(href))
    payload=download(url,MAX_ZIP)
    assert zipfile.is_zipfile(BytesIO(payload)), ("Not a valid real material archive",url,payload[:20])
    archive=zipfile.ZipFile(BytesIO(payload))
    photos=[]
    for member in archive.infolist():
        if member.is_dir():continue
        if member.file_size>20000000:continue
        if member.filename.lower().endswith((".png",".jpg",".jpeg",".webp")):
            b=archive.read(member)
            pic=Image.open(BytesIO(b))
            if min(pic.size)>=256:
                photos.append((member.filename,b,pic.copy()))
    assert len(photos)>=3,("Insufficient actual PBR maps",archive.namelist())
    index=[]
    for name,content,image in photos:
        safe=Path(name).name
        (OUT/safe).write_bytes(content)
        index.append({"file":safe,"original_path":name,
                      "sha256":hashlib.sha256(content).hexdigest(),
                      "resolution":list(image.size),
                      "mean_rgb":[round(n,2) for n in ImageStat.Stat(image.convert("RGB")).mean]})
    categories=" ".join(x["file"].lower() for x in index)
    assert any(k in categories for k in ("normal","nor")),index
    assert any(k in categories for k in ("rough","orm")),index
    assert any(k in categories for k in ("color","albedo","base")),index
    manifest={"source":INDEX,"material":"Nero Marquina black marble",
              "license":"CC0 according to publisher library",
              "original_selected_blenderkit_material":False,
              "source_pack_download_url":url,"original_zip_sha256":hashlib.sha256(payload).hexdigest(),
              "textures":index,"actual_PBR_channels_acquired":True}
    (OUT/"real_cc0_material_manifest.json").write_text(json.dumps(manifest,indent=2)+"\n")
    print("PASS_REAL_PROC_TEXTURE_NERO_CC0_MAPS",json.dumps(manifest),flush=True)

if __name__=="__main__":main()
