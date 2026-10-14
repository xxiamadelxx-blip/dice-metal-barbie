#!/usr/bin/env python3
"""Bounded public metadata-only material/model discovery; never scrape signed downloads.

No authentication, CAPTCHA bypass, speculative license, or redistribution.
Descriptions/previews are NOT PBR file download/validation.
"""
import html
import json
import re
import sys
import time
from html.parser import HTMLParser
from pathlib import Path
from urllib.error import HTTPError, URLError
from urllib.request import Request, urlopen

SOURCES = [
 {"name":"Selected Procedural Obsidian","kind":"material","url":"https://www.blenderkit.com/asset-gallery-detail/92e31cbc-5b4e-4ead-a966-84bf106808c3/","license":"BlenderKit free listing; actual file/license metadata not checked","priority":"OWNER_SELECTED"},
 {"name":"Obsidian Procedural alternative","kind":"material","url":"https://www.blenderkit.com/asset-gallery-detail/d735310a-61f2-4cc9-87a9-aa883bd54d7a/","license":"BlenderKit Free listing; actual license not checked","priority":"SECONDARY_VISUAL"},
 {"name":"Sketchfab black-obsidian D20 model","kind":"3d_model","url":"https://sketchfab.com/3d-models/d20-polyhedral-dice-3e9f731177e5458986df6f1c2f690dd7","license":"CC BY attribution stated on model listing","priority":"REFERENCE_ONLY"},
 {"name":"CraftPBR polished obsidian marble","kind":"pbr_material","url":"https://craftpbr.com/material/LxSKwsj6ZHobzuMYDcva","license":"CC0 stated on public listing, sign-in to download; purple in prompt","priority":"REJECT_PURPLE_OR_LOGIN"},
 {"name":"Poliigon knapped obsidian","kind":"pbr_material","url":"https://www.poliigon.com/texture/knapped-obsidian-stone-texture/11179","license":"Premium paid, NOT FREE","priority":"REJECT_PAID"},
 {"name":"CGAxis black obsidian","kind":"pbr_material","url":"https://cgaxis.com/product/black-obsidian-6727/","license":"No free license established","priority":"REVIEW_LICENSE"},
 {"name":"cgbookcase CC0 catalog","kind":"texture_catalog","url":"https://www.cgbookcase.com/textures","license":"CC0 catalog, specific obsidian material not established","priority":"ALTERNATIVE_RESEARCH"},
 {"name":"Opeture free texture catalog","kind":"texture_catalog","url":"https://www.opeture.com/","license":"Free commercial use with redistribution restrictions","priority":"ALTERNATIVE_RESEARCH"},
 {"name":"Poly Haven CC0 texture catalog","kind":"texture_catalog","url":"https://api.polyhaven.com/assets?t=textures","license":"CC0 library, verify material ID individually","priority":"SEARCH_CC0"},
 {"name":"ambientCG public API (Obsidian search)","kind":"texture_catalog","url":"https://ambientcg.com/api/v2/full_json?limit=25&search=Obsidian","license":"CC0 catalog, query may return zero results","priority":"SEARCH_CC0"}
]
MAX_BYTES=1250000
AGENT="DiceResearchM5/1.0 (public asset license metadata check; no downloads)"

class Page(HTMLParser):
    def __init__(self):
        super().__init__()
        self.title=""
        self.in_title=False
        self.meta={}
        self.links=[]
    def handle_starttag(self,tag,attrs):
        attrs=dict(attrs)
        if tag=="title":self.in_title=True
        if tag=="meta":
            name=(attrs.get("name") or attrs.get("property") or "").lower()
            if name in ["description","og:description","og:title","og:image"]:
                self.meta[name]=(attrs.get("content") or "")[:400]
        if tag=="a":
            href=attrs.get("href","")
            if re.search(r"\.(?:blend|glb|gltf|zip|png|jpg|exr)(?:[?#]|$)",href,re.I):
                self.links.append(href.split("?")[0][:256])
    def handle_endtag(self,tag):
        if tag=="title":self.in_title=False
    def handle_data(self,value):
        if self.in_title:self.title+=value

def observe(src):
    entry={**src,"status":"NOT_REQUESTED","retrieved_download":False,
           "actual_pbr_channel_bytes_validated":False,"asset_licence_verified_from_file":False}
    req=Request(src["url"],headers={"User-Agent":AGENT,"Accept":"application/json,text/html"})
    try:
        with urlopen(req,timeout=14) as response:
            content_type=response.headers.get("Content-Type","")
            payload=response.read(MAX_BYTES+1)
            if len(payload)>MAX_BYTES:
                entry.update(status="RESPONSE_TOO_LARGE",byte_cap=MAX_BYTES)
                return entry
            entry["status"]="HTTP_"+str(response.status)
            entry["response_content_type"]=content_type[:100]
            entry["bytes"]=len(payload)
            if "json" in content_type or src["url"].find("api.")!=-1:
                try:
                    j=json.loads(payload)
                    if isinstance(j,dict):
                        entry["json_top_keys"]=list(j)[:20]
                        if "polyhaven" in src["url"]:
                            choices=[]
                            for asset_id,meta in j.items():
                                label=str(meta.get("name",""))
                                desc=str(meta.get("description",""))
                                if any(term in (label+" "+desc).lower()
                                   for term in ["obsidian","black marble","black glass","polished stone","glossy black"]):
                                    choices.append({"id":asset_id,"name":label,"url":"https://polyhaven.com/a/"+asset_id})
                            entry["polished_observations"]=choices[:15]
                        if "ambientcg" in src["url"]:
                            entry["items_count"]=len(j.get("foundAssets",[])) if isinstance(j.get("foundAssets"),list) else None
                            entry["possible_assets"]=str(j.get("foundAssets",[]))[:650]
                except json.JSONDecodeError:
                    entry["status"]="INVALID_JSON"
            elif "html" in content_type:
                parser=Page()
                parser.feed(payload.decode("utf-8","replace"))
                entry["page_title"]=html.unescape(parser.title.strip())[:230]
                entry["meta"]=parser.meta
                entry["public_download_href_candidates"]=parser.links[:8]
                entry["download_link_not_validated"]=True
    except HTTPError as e:
        entry.update(status="HTTP_"+str(e.code),response_error="server rejected metadata request")
    except (URLError,TimeoutError,OSError) as e:
        entry.update(status="NETWORK_ERROR",response_error=type(e).__name__)
    return entry

def main():
    directory=Path(sys.argv[1] if len(sys.argv)>1 else "build/material-intake")
    directory.mkdir(parents=True,exist_ok=True)
    obs=[]
    for src in SOURCES:
        item=observe(src)
        obs.append(item)
        print("OBSIDIAN_PUBLIC_METADATA",item["name"],item["status"],flush=True)
        time.sleep(.15)
    report={"method":"public allowed metadata only, size/time limited; no auth/cookies/download API bypass",
            "source_count":len(obs),"owner_exact_selected":SOURCES[0]["url"],
            "pbr_png_files_downloaded":0,
            "actual_source_license_verifications":0,
            "premium_model_png_asset_ready":False,
            "candidates":obs}
    out=directory/"polished_obsidian_public_source_audit.json"
    out.write_text(json.dumps(report,ensure_ascii=False,indent=2)+"\\n",encoding="utf-8")
    print("PASS_OBSIDIAN_SOURCE_PAGES_AUDITED",len(obs),str(out),flush=True)

if __name__=="__main__":main()
