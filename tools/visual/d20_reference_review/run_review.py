#!/usr/bin/env python3
"""Capture the imported user asset in a real Godot window, with strict receipts."""
import argparse
import hashlib
import json
import os
from pathlib import Path
import re
import random
import shutil
import socket
import subprocess
import time

EXPECTED_SOURCE = "c5d971370fae51328461cbd220293d9445a14d7fd6f182b623f52551dbb8fa27"

parser = argparse.ArgumentParser()
parser.add_argument("--godot", required=True)
parser.add_argument("--xvfb", default="Xvfb")
parser.add_argument("--libraries")
parser.add_argument("--vulkan-icd")
parser.add_argument("--renderer", choices=["mobile", "gl_compatibility"], default="mobile")
parser.add_argument("--label", default="02-mobile-baseline")
parser.add_argument("--no-shadows", action="store_true")
parser.add_argument("--disable-lod", action="store_true")
parser.add_argument("--balanced-studio", action="store_true")
parser.add_argument("--restore-clearcoat", action="store_true")
parser.add_argument("--refined-studio", action="store_true")
parser.add_argument("--final-studio", action="store_true")
parser.add_argument("--source", default="d20_obsidian_gold.glb")
args = parser.parse_args()
assert re.fullmatch(r"[a-zA-Z0-9_-]+", args.label), "Unsafe evidence label"
assert re.fullmatch(r"[a-zA-Z0-9_.-]+\.glb", args.source), "Source must be a local GLB filename"
project = Path(__file__).resolve().parent
assert hashlib.sha256((project / "d20_obsidian_gold.glb").read_bytes()).hexdigest() == EXPECTED_SOURCE
expected_capture_source = EXPECTED_SOURCE
if args.source != "d20_obsidian_gold.glb":
    candidate = json.loads((project / "candidate-manifest.json").read_text())
    assert candidate["candidate_file"] == args.source
    assert candidate["original_sha256"] == EXPECTED_SOURCE
    expected_capture_source = candidate["candidate_sha256"]
assert hashlib.sha256((project / args.source).read_bytes()).hexdigest() == expected_capture_source
output = project / "evidence" / args.label
output.mkdir(parents=True, exist_ok=True)
for source in ["project.godot", "review.gd", "run_review.py"]:
    shutil.copy2(project / source, output / ("capture-" + source))
env = os.environ.copy()
display = next(n for n in random.sample(range(100, 500), 400) if not Path(f"/tmp/.X{n}-lock").exists())
env.update({"DISPLAY": f"127.0.0.1:{display}", "LIBGL_ALWAYS_SOFTWARE": "1", "GODOT_SILENCE_ROOT_WARNING": "1"})
if args.libraries:
    env["LD_LIBRARY_PATH"] = args.libraries + (":" + env["LD_LIBRARY_PATH"] if env.get("LD_LIBRARY_PATH") else "")
if args.vulkan_icd:
    env["VK_ICD_FILENAMES"] = str(Path(args.vulkan_icd).resolve())
with (output / "xvfb.log").open("w") as server_log:
    server = subprocess.Popen([args.xvfb, f":{display}", "-screen", "0", "1024x1024x24", "-ac", "-noreset", "-nolisten", "local", "-nolisten", "unix", "-listen", "tcp", "-fp", ""], env=env, stdout=server_log, stderr=subprocess.STDOUT)
    try:
        for _ in range(80):
            if server.poll() is not None:
                raise RuntimeError("Xvfb failed; inspect " + str(output / "xvfb.log"))
            try:
                with socket.create_connection(("127.0.0.1", 6000 + display), timeout=0.1):
                    break
            except OSError:
                time.sleep(0.05)
        else:
            raise RuntimeError("Local X display did not start")
        command = [args.godot, "--path", str(project), "--rendering-method", args.renderer, "--rendering-driver", "vulkan" if args.renderer == "mobile" else "opengl3", "--audio-driver", "Dummy", "--script", "res://review.gd", "--log-file", str(output / "engine.log"), "--", "--output=" + args.label]
        command.append("--source=" + args.source)
        if args.no_shadows:
            command.append("--no-shadows")
        if args.disable_lod:
            command.append("--disable-lod")
        if args.balanced_studio:
            command.append("--balanced-studio")
        if args.restore_clearcoat:
            command.append("--restore-clearcoat")
        if args.refined_studio:
            command.append("--refined-studio")
        if args.final_studio:
            command.append("--final-studio")
        (output / "command.json").write_text(json.dumps(command, indent=2) + "\n")
        result = subprocess.run(command, env=env, cwd=project, timeout=180, capture_output=True, text=True)
        combined = result.stdout + result.stderr
        (output / "process.log").write_text(combined)
        print(combined, flush=True)
        assert result.returncode == 0, "Godot process failed"
        assert not re.search(r"SCRIPT ERROR|Parse Error|Compile Error|Invalid call|Assertion failed|Program crashed", combined), "Godot script failed despite process exit"
        assert "D20_REVIEW_REAL_CAPTURE_DONE" in combined, "Capture completion absent"
        receipt = json.loads((output / "render-receipt.json").read_text())
        assert receipt["renderer"] == args.renderer, "Renderer fallback occurred"
        assert receipt["source_sha256"] == expected_capture_source
        assert receipt["original_upload_sha256"] == EXPECTED_SOURCE
        assert receipt["mesh_count"] == 23 and receipt["source_materials_preserved"] is True
        for name in receipt["captures"]:
            image = output / name
            assert image.read_bytes()[:8] == b"\x89PNG\r\n\x1a\n", "PNG is missing"
        print("REAL_CAPTURE_AND_SOURCE_CHECKS_PASS", output, flush=True)
    finally:
        server.terminate()
        try:
            server.wait(timeout=5)
        except subprocess.TimeoutExpired:
            server.kill()
            server.wait()
