#!/usr/bin/env python3
"""Fetch ONLY the owner-selected free Blendkit procedural obsidian material.

License-aware, anonymous HTTPS intake for an ISOLATED Blender art experiment.
No API key, no user credentials, no runtime game dependency. The downloaded
third-party .blend is transient and MUST NOT be uploaded or committed.
"""
import argparse
import hashlib
import json
import sys
from pathlib import Path
from urllib.parse import urlencode
from urllib.request import Request, urlopen

ASSET_BASE_ID = "92e31cbc-5b4e-4ead-a966-84bf106808c3"
ASSET_PAGE = "https://www.blenderkit.com/asset-gallery-detail/" + ASSET_BASE_ID + "/"
SEARCH = "https://www.blenderkit.com/api/v1/search/"
MAX_BYTES = 25 * 1024 * 1024

def get_bytes(url, *, limit=MAX_BYTES):
    request = Request(url, headers={"User-Agent": "DiceRoller-M5-free-material-intake/1.0",
                                    "Accept": "application/json,application/octet-stream"})
    with urlopen(request, timeout=35) as response:
        length = response.headers.get("Content-Length")
        if length is not None and int(length) > limit:
            raise ValueError("Asset exceeds 25 MiB guardrail")
        payload = response.read(limit + 1)
    if len(payload) > limit:
        raise ValueError("Asset exceeds 25 MiB guardrail")
    return payload

def get_json(url):
    return json.loads(get_bytes(url, limit=4 * 1024 * 1024).decode("utf-8"))

def get_one_asset():
    query = urlencode({"query": "asset_base_id:" + ASSET_BASE_ID,
                       "page_size": 25, "dict_parameters": 1})
    data = get_json(SEARCH + "?" + query)
    entries = data.get("results", [])
    found = [a for a in entries if str(a.get("assetBaseId") or a.get("asset_base_id") or
                                          a.get("baseId") or "") == ASSET_BASE_ID]
    if len(found) != 1:
        raise RuntimeError("Exact user-selected asset ID not found in public Blendkit API")
    return found[0]

def license_label(asset):
    value = asset.get("license", "")
    if isinstance(value, dict):
        value = value.get("name") or value.get("slug") or value.get("label") or ""
    return str(value).lower().replace("-", "_").replace(" ", "_")

def choose_download(asset):
    files = asset.get("files") or []
    # A procedural node material must arrive as its Blender data, not a JPG.
    for file_type in ("blend", "resolution_2K", "resolution_1K"):
        for item in files:
            if item.get("fileType") == file_type and item.get("downloadUrl"):
                return item
    raise RuntimeError("Exact asset has no public Blender-compatible download URL")

def fetch_material(destination, manifest):
    asset = get_one_asset()
    name = str(asset.get("name", ""))
    typ = str(asset.get("assetType", "")).lower()
    if name.lower().strip() != "procedural obsidian" or typ != "material":
        raise ValueError("Wrong asset type/name; refusing substitute: " + name)
    license_id = license_label(asset)
    if license_id not in ("royalty_free", "cc0", "cc_0", "creative_commons_zero"):
        raise RuntimeError("License identifier not verified for third-party material: " + repr(license_id))
    if asset.get("isFree") is False or asset.get("is_free") is False:
        raise RuntimeError("Selected asset is no longer free; no purchase allowed")
    chosen = choose_download(asset)
    resolver = get_json(chosen["downloadUrl"])
    direct = resolver.get("filePath") or resolver.get("download_url") or resolver.get("url")
    if not isinstance(direct, str) or not direct.startswith("https://"):
        raise RuntimeError("Blendkit did not resolve anonymous HTTPS file URL")
    raw = get_bytes(direct)
    if not raw.startswith(b"BLENDER"):
        raise RuntimeError("Download is not a valid Blender .blend header")
    destination.parent.mkdir(parents=True, exist_ok=True)
    destination.write_bytes(raw)
    report = {"status": "ANONYMOUS_FREE_ASSET_DOWNLOADED",
              "asset_page": ASSET_PAGE, "asset_base_id": ASSET_BASE_ID,
              "asset_id": asset.get("id"), "name": name, "license": license_id,
              "file_type": chosen["fileType"], "sha256": hashlib.sha256(raw).hexdigest(),
              "byte_count": len(raw), "runtime_dependency": False,
              "third_party_binary_committed": False}
    manifest.parent.mkdir(parents=True, exist_ok=True)
    manifest.write_text(json.dumps(report, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
    print("PASS_SELECTED_FREE_BLENDKIT_OBSIDIAN " + json.dumps(report))
    return report

def main():
    p = argparse.ArgumentParser()
    p.add_argument("--download-to", type=Path, required=True)
    p.add_argument("--manifest", type=Path, required=True)
    a = p.parse_args()
    try:
        fetch_material(a.download_to, a.manifest)
    except Exception as exc:
        # Public, redacted error report; NEVER emit signed download URLs/tokens.
        error = {"status": "NOT_VERIFIED", "asset_page": ASSET_PAGE,
                 "asset_base_id": ASSET_BASE_ID, "exception_type": type(exc).__name__,
                 "reason": str(exc)[:250].split("https://")[0],
                 "third_party_binary_committed": False}
        a.manifest.parent.mkdir(parents=True, exist_ok=True)
        a.manifest.write_text(json.dumps(error, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
        print("BLENDKIT_FREE_INTAKE_BLOCKED " + json.dumps(error), file=sys.stderr)
        sys.exit(1)

if __name__ == "__main__":
    main()
