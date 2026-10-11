#!/usr/bin/env python3
"""Small, offline, verifiable engineering checks. No live services or installers."""
from __future__ import annotations

import argparse
from array import array
import json
import math
from pathlib import Path
import re
import sys
import wave

ROOT = Path(__file__).resolve().parents[1]
LOAD = re.compile(r'''(?:preload|load)\(\s*["']res://([^"'\s]+)["']\s*\)''')
SECRET_PATTERNS = {
    "private-key-block": re.compile(r"-----BEGIN (?:RSA |EC |OPENSSH )?PRIVATE KEY-----"),
    "github-access-token": re.compile(r"gh[pousr]_[A-Za-z0-9_]{36,}"),
    "aws-access-key": re.compile(r"AKIA[A-Z0-9]{16}"),
    "openai-secret-key": re.compile(r"sk-(?:proj-)?[A-Za-z0-9_-]{32,}"),
}


def gd_architecture(root: Path) -> dict:
    """Inspect literal resource links only; dynamic loading stays unverified."""
    src = root / "src"
    edges: dict[str, list[str]] = {}
    problems: list[dict] = []
    for filename in sorted(src.rglob("*.gd")) if src.is_dir() else []:
        rel = filename.relative_to(root).as_posix()
        content = filename.read_text(encoding="utf-8")
        refs = [v for v in LOAD.findall(content) if v.startswith("src/") and v.endswith(".gd")]
        edges[rel] = []
        for target in refs:
            edges[rel].append(target)
            if not (root / target).is_file():
                problems.append({"source": rel, "target": target, "problem": "missing static source"})
            if (rel.startswith("src/core/") and (target.startswith("src/ui/") or target.startswith("src/visual/"))) or (
                    rel.startswith("src/dice/") and target.startswith("src/ui/")):
                problems.append({"source": rel, "target": target, "problem": "forbidden runtime layering"})
    visited: set[str] = set()
    visiting: set[str] = set()
    cycles: set[str] = set()

    def walk(node: str, stack: list[str]) -> None:
        if node in visiting:
            cycles.add(" -> ".join(stack + [node]))
            return
        if node in visited:
            return
        visiting.add(node)
        for dep in edges.get(node, []):
            if dep in edges:
                walk(dep, stack + [node])
        visiting.remove(node)
        visited.add(node)

    for node in edges:
        walk(node, [])
    for cycle in sorted(cycles):
        problems.append({"problem": "static dependency cycle", "path": cycle})
    return {"gate": "architecture", "verdict": "FAIL" if problems else "PASS_STATIC_ONLY",
            "sources": len(edges), "edges": sum(len(v) for v in edges.values()),
            "findings": problems, "scope_note": "Literal preload/load edges only; dynamic reflection NOT_VERIFIED"}


def secrets(root: Path) -> dict:
    """Redacted scan on tracked-like source locations; excludes docs/test fixtures."""
    findings = []
    candidates = [root / "src", root / "scripts", root / ".github/workflows"]
    suffixes = {".gd", ".py", ".yml", ".yaml", ".json", ".sh", ".cfg"}
    checked = 0
    for source_dir in candidates:
        if not source_dir.is_dir():
            continue
        for path in source_dir.rglob("*"):
            if not path.is_file() or path.is_symlink() or path.suffix not in suffixes:
                continue
            if path.stat().st_size > 512000:
                continue
            try:
                txt = path.read_text(encoding="utf-8")
            except UnicodeError:
                continue
            checked += 1
            for number, line in enumerate(txt.splitlines(), start=1):
                for rule, expression in SECRET_PATTERNS.items():
                    if expression.search(line):
                        findings.append({"file": path.relative_to(root).as_posix(), "line": number, "rule": rule})
    return {"gate": "security", "verdict": "FAIL" if findings else "PASS_PATTERN_ONLY",
            "scanned_files": checked, "findings": findings,
            "scope_note": "No secret bytes emitted. Pattern scan != full security audit or Gitleaks/Semgrep."}


def wav_audio(filename: Path) -> dict:
    """PCM16 peak, clipping and silence check; NOT a subjective audio review."""
    with wave.open(str(filename), "rb") as sound:
        nchannels, rate, width, nframes = (sound.getnchannels(), sound.getframerate(),
                                             sound.getsampwidth(), sound.getnframes())
        if width != 2 or not 1 <= nchannels <= 2 or rate < 8000 or nframes <= 0:
            return {"gate": "audio", "verdict": "NOT_VERIFIED", "reason": "unsupported/empty PCM16 WAV"}
        peak = 0
        high = 0
        total = 0
        dc_sum = 0
        while True:
            frame = sound.readframes(16384)
            if not frame:
                break
            samples = array("h")
            samples.frombytes(frame)
            if sys.byteorder != "little":
                samples.byteswap()
            for value in samples:
                sample = abs(value)
                peak = max(peak, sample)
                high += int(sample >= 32760)
                total += 1
                dc_sum += value
    if total == 0:
        return {"gate": "audio", "verdict": "NOT_VERIFIED", "reason": "no decoded samples"}
    dbfs = 20 * math.log10(peak / 32768) if peak else float("-inf")
    ratio = high / total
    silence = peak < 328
    return {"gate": "audio", "verdict": "FAIL" if silence or ratio > 0.001 else "PASS_SIGNAL_ONLY",
            "duration_s": round(nframes / rate, 4), "channels": nchannels,
            "sample_rate_hz": rate, "peak_dbfs": None if silence else round(dbfs, 2),
            "clipped_fraction": round(ratio, 6), "dc_offset_fraction": round(dc_sum / (total * 32768), 6),
            "scope_note": "Sound source, physics sync and real device audition NOT_VERIFIED"}


def frame_timings(data: dict) -> dict:
    """Fail closed on unknown hardware/source, never relabel Mesa FPS as phone."""
    samples = data.get("frame_ms")
    kind = data.get("device_kind")
    if kind not in ("phone", "emulator", "mesa") or not isinstance(samples, list) or len(samples) < 30:
        return {"gate": "performance", "verdict": "NOT_VERIFIED", "reason": "30+ raw frame times and device kind needed"}
    if any(type(x) not in (int, float) or not 0 < x < 10000 or not math.isfinite(x) for x in samples):
        return {"gate": "performance", "verdict": "NOT_VERIFIED", "reason": "invalid durations"}
    expected_fps = data.get("target_fps", 60)
    if type(expected_fps) not in (int, float) or not 1 <= expected_fps <= 240:
        return {"gate": "performance", "verdict": "NOT_VERIFIED", "reason": "invalid FPS target"}
    sorted_frames = sorted(samples)
    p95 = sorted_frames[math.ceil(0.95 * len(sorted_frames)) - 1]
    budget = 1000 / expected_fps
    return {
        "gate": "performance",
        "verdict": "PASS_PHONE_FRAMETIME" if kind == "phone" and p95 <= budget else
                   ("FAIL" if kind == "phone" else "NOT_VERIFIED_DEVICE"),
        "device_kind": kind, "device_model": data.get("device_model", "UNKNOWN"),
        "sample_count": len(samples), "p95_frame_ms": round(p95, 3),
        "budget_ms": round(budget, 3), "over_budget": sum(x > budget for x in samples),
        "scope_note": "Declared source is not externally authenticated; attach original profiler trace",
    }


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    commands = parser.add_subparsers(dest="gate", required=True)
    commands.add_parser("architecture")
    commands.add_parser("security")
    wav = commands.add_parser("audio")
    wav.add_argument("--file", type=Path, required=True)
    perf = commands.add_parser("performance")
    perf.add_argument("--input", type=Path, required=True)
    args = parser.parse_args()
    try:
        if args.gate == "architecture":
            result = gd_architecture(ROOT)
        elif args.gate == "security":
            result = secrets(ROOT)
        elif args.gate == "audio":
            result = wav_audio(args.file)
        else:
            result = frame_timings(json.loads(args.input.read_text(encoding="utf-8")))
        print(json.dumps(result, ensure_ascii=False, indent=2, allow_nan=False))
        return 2 if result["verdict"] == "FAIL" else 0
    except (OSError, ValueError, wave.Error, json.JSONDecodeError) as exc:
        print(json.dumps({"gate": args.gate, "verdict": "NOT_VERIFIED", "reason": str(exc)}), file=sys.stderr)
        return 2


if __name__ == "__main__":
    raise SystemExit(main())
