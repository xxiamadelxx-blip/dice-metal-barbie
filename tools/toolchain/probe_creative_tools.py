"""Audit *actual* Ubuntu binary installs and bounded CLI smoke in Actions.

Presence, CLI launch and authored export are distinct levels. Never claim
production-ready simply because apt/dpkg or unpack succeeded.
"""
import json
import os
import shutil
import subprocess
import sys
from pathlib import Path

TOOLS = {
    "gimp": {"package": "gimp", "binary": "gimp", "args": ["--version"]},
    "krita": {"package": "krita", "binary": "krita", "args": ["--version"]},
    "meshlab": {"package": "meshlab", "binary": "meshlab", "args": ["-h"]},
}
def run(cmd, timeout=15, env=None):
    try:
        p = subprocess.run(cmd, stdout=subprocess.PIPE, stderr=subprocess.STDOUT,
                           text=True, timeout=timeout, env=env, check=False)
        return {"exit_code": p.returncode, "output": p.stdout[-2400:], "timeout": False}
    except subprocess.TimeoutExpired as err:
        return {"exit_code": None, "output": str(err), "timeout": True}
    except OSError as err:
        return {"exit_code": None, "output": str(err), "timeout": False}

def main(root):
    root.mkdir(parents=True, exist_ok=True)
    report = {"runner": "GitHub Actions ubuntu-24.04 x86_64",
              "requirements": "noninteractive CLI evidence, not GUI/headless art export",
              "results": {}}
    for name, data in TOOLS.items():
        binary = shutil.which(data["binary"])
        package = run(["dpkg-query", "-W", "-f=${Status} ${Version}", data["package"]])
        item = {"apt_package": data["package"], "package": package,
                "binary": binary, "headless_export": "NOT_VERIFIED"}
        if binary:
            attempt = run([binary] + data["args"], timeout=12)
            # Some Meshlab versions require a display even to print -h;
            # only a successful command is cli_ok.
            item["cli"] = attempt
            item["status"] = "cli_ok" if attempt["exit_code"] == 0 else "installed"
        else:
            item["status"] = "not_found"
        report["results"][name] = item
    mm = root / "material-maker"
    digest_file = root / "material-maker-sha256.log"
    archive_exit = (root / "material-maker.exit")
    archive_result = archive_exit.read_text().strip() if archive_exit.exists() else "not-run"
    candidates = []
    if archive_result == "0":
        for path in mm.rglob("*"):
            if not path.is_file() or not os.access(path, os.X_OK):
                continue
            if "material" not in path.name.lower() and "maker" not in path.name.lower():
                continue
            try:
                if path.open("rb").read(4) == bytes.fromhex("7f454c46"):
                    candidates.append(str(path))
            except OSError:
                continue
    item = {"pinned_upstream_sha256": "c8e3b6f1993540875d26fe49645c91511bba36cda0412c715bd13249f7141647",
            "archive_exit": archive_result,
            "digest_verified": digest_file.exists() and "OK" in digest_file.read_text(),
            "executable_candidates": candidates,
            "headless_export": "NOT_VERIFIED"}
    if candidates and item["digest_verified"]:
        item["status"] = "installed"
        # CLI may require graphical initialization. Bound this probe to 15s.
        attempt = run(["xvfb-run", "-a", candidates[0], "--version"], timeout=15)
        item["cli"] = attempt
        if attempt["exit_code"] == 0:
            item["status"] = "cli_ok"
    else:
        item["status"] = "install_failed" if archive_result != "0" else "no_elf_executable"
    report["results"]["material_maker"] = item
    out = root / "probe-report.json"
    out.write_text(json.dumps(report, indent=2, ensure_ascii=False) + "\n")
    for key, entry in report["results"].items():
        print(f"{key}: {entry['status']} | export: {entry['headless_export']}")
    print(f"JSON evidence: {out}")

if __name__ == "__main__":
    main(Path(sys.argv[1] if len(sys.argv) > 1 else "build/tool-probe"))
