#!/usr/bin/env python3
"""Dice engineering-router: canonical entry/recovery and toolchain dispatch.

No model calls, network, installs, hidden pushes or automatic feature edits.
Entrypoint: python3 scripts/engineering_router.py enter --intent "продолжай"
"""
from __future__ import annotations

import argparse
import hashlib
from datetime import datetime, timezone
import json
import os
from pathlib import Path
import re
import shutil
import subprocess
import sys
import tempfile
from typing import Any

ROOT = Path(__file__).resolve().parents[1]
REGISTRY = ROOT / "config" / "engineering_routes.json"
STATE = ROOT / "docs" / "handoff" / "ACTIVE_ROUTING_HANDOFF.json"
EXPECTED_REPO = "xxiamadelxx-blip/dice-metal-barbie"
STATUSES = {"in_progress", "blocked", "verified", "paused", "not_verified"}
MODES = {"continue", "stuck", "handoff", "new-task"}
BINARIES = ("git", "python3", "godot", "blender", "ffmpeg", "ffprobe", "sox",
            "gdformat", "gdlint", "meshlabserver", "inkscape", "openscad",
            "gitleaks", "semgrep", "trivy", "adb", "apksigner", "magick")
CONTINUE_WORDS = ("продолж", "continue", "resume", "дальше", "go on")
STUCK_WORDS = ("завис", "застр", "stuck", "hang", "ошибка агента")
HANDOFF_WORDS = ("передач", "handoff", "новому агент", "смена агента", "new agent")


class RouterError(Exception):
    pass


def now() -> str:
    return datetime.now(timezone.utc).isoformat(timespec="seconds")


def text(value: Any) -> bool:
    return isinstance(value, str) and bool(value.strip())


def read_json(path: Path) -> dict[str, Any]:
    try:
        obj = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, UnicodeError, ValueError) as exc:
        raise RouterError(f"cannot read {path}: {exc}") from exc
    if not isinstance(obj, dict):
        raise RouterError(f"expected object in {path}")
    return obj


def load_registry(root: Path = ROOT) -> dict[str, Any]:
    reg = read_json(root / "config" / "engineering_routes.json")
    problems = validate_registry(reg)
    if problems:
        raise RouterError("; ".join(problems))
    return reg


def validate_registry(reg: dict[str, Any]) -> list[str]:
    errors = []
    if reg.get("schema_version") != 1:
        errors.append("unsupported registry schema version")
    if reg.get("repository") != EXPECTED_REPO:
        errors.append("wrong repository identity")
    if not text(reg.get("entrypoint")) or not text(reg.get("policy")):
        errors.append("entrypoint/policy must exist")
    routes = reg.get("routes")
    if not isinstance(routes, list) or len(routes) < 10:
        return errors + ["route registry needs at least ten domain routes"]
    seen: set[str] = set()
    for route in routes:
        if not isinstance(route, dict):
            errors.append("invalid route object")
            continue
        name = route.get("id")
        if not text(name) or not re.fullmatch("[a-z][a-z0-9-]*", name):
            errors.append("invalid route id")
            continue
        if name in seen:
            errors.append(f"duplicate route: {name}")
        seen.add(name)
        for key in ("title", "fallback"):
            if not text(route.get(key)):
                errors.append(f"{name} missing {key}")
        for key in ("triggers", "paths", "checks", "artifacts", "requires"):
            arr = route.get(key)
            if not isinstance(arr, list) or not arr or not all(text(item) for item in arr):
                errors.append(f"{name} invalid {key}")
        tools = route.get("tools")
        if not isinstance(tools, list) or not tools or any(
                not isinstance(t, dict) or not text(t.get("name")) or not text(t.get("kind"))
                for t in tools):
            errors.append(f"{name} invalid tool definitions")
        if type(route.get("priority")) is not int or not 1 <= route["priority"] <= 100:
            errors.append(f"{name} invalid priority")
    for required in ("agent-operations", "code", "architecture", "creative-3d",
                     "audio-haptics", "security", "performance", "android-release",
                     "qa-critic"):
        if required not in seen:
            errors.append("missing mandatory route: " + required)
    return errors


def validate_state(state: dict[str, Any], registry: dict[str, Any]) -> list[str]:
    errors = []
    if state.get("schema_version") != 1:
        errors.append("invalid handoff version")
    if state.get("repository") != EXPECTED_REPO:
        errors.append("handoff cross-repository contamination")
    active = state.get("active")
    if not isinstance(active, dict):
        return errors + ["active handoff must be an object"]
    ids = {r["id"] for r in registry["routes"]}
    if active.get("route") not in ids:
        errors.append("active route not in registry")
    if active.get("status") not in STATUSES:
        errors.append("invalid active status")
    for key in ("task", "next_action", "owner"):
        if not text(active.get(key)):
            errors.append(f"missing handoff {key}")
    for key in ("blockers", "evidence"):
        if not isinstance(active.get(key), list):
            errors.append("invalid handoff " + key)
    if active.get("status") == "blocked" and not active.get("blockers"):
        errors.append("blocked task without specific blocker")
    if active.get("status") == "verified" and not active.get("evidence"):
        errors.append("verified state without original evidence")
    if "incidents" in state and not isinstance(state["incidents"], dict):
        errors.append("incident ledger must be object")
    return errors


def git_info(root: Path) -> dict[str, str]:
    def cmd(*args: str) -> str:
        try:
            p = subprocess.run(["git", *args], cwd=root, capture_output=True,
                               text=True, timeout=15, check=False)
            return p.stdout.strip() if p.returncode == 0 else ""
        except (FileNotFoundError, subprocess.TimeoutExpired):
            return ""
    return {
        "branch": cmd("branch", "--show-current") or "UNKNOWN",
        "sha": cmd("rev-parse", "HEAD") or "NOT_VERIFIED",
        "dirty": "yes" if cmd("status", "--porcelain") else "no",
    }


def parse_mode(intent: str) -> str:
    term = intent.lower()
    if (re.search(r"(?<![а-яёa-z])(?:завис(?!им)|застр|stuck\\b|hang\\b)", term)
            or "ошибка агента" in term):
        return "stuck"
    if any(x in term for x in HANDOFF_WORDS):
        return "handoff"
    if any(x in term for x in CONTINUE_WORDS):
        return "continue"
    return "new-task"


def route_for(intent: str, registry: dict[str, Any],
              active: dict[str, Any], override: str | None = None) -> dict[str, Any]:
    routes = {r["id"]: r for r in registry["routes"]}
    if override is not None:
        if override not in routes:
            raise RouterError("unknown route: " + override)
        return routes[override]
    mode = parse_mode(intent)
    if mode in ("stuck", "handoff") or (mode == "continue" and len(intent.split()) < 5):
        return routes[active["route"]]
    query = intent.lower()
    scores = []
    for r in routes.values():
        matches = [t for t in r["triggers"] if t.lower() in query]
        if matches:
            scores.append((len(matches), r["priority"], max(map(len, matches)), r["id"]))
    if not scores:
        return routes[active["route"]] if mode == "continue" else routes["agent-operations"]
    return routes[max(scores)[-1]]


def write_atomic(path: Path, data: dict[str, Any]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    candidate = None
    try:
        with tempfile.NamedTemporaryFile("w", encoding="utf-8", dir=path.parent,
                                         prefix="." + path.name + ".", suffix=".tmp",
                                         delete=False) as f:
            candidate = Path(f.name)
            json.dump(data, f, ensure_ascii=False, indent=2)
            f.write("\n")
            f.flush()
            os.fsync(f.fileno())
        os.replace(candidate, path)
    finally:
        if candidate is not None and candidate.exists():
            candidate.unlink()


def probe_tools(root: Path = ROOT) -> dict[str, str]:
    results = {}
    for binary in BINARIES:
        p = shutil.which(binary)
        results[binary] = "binary-found:" + p if p else "not-detected"
    # Repo reference != actual installed tool: file presence is a separate axis.
    results["gauntlet_cli"] = "source-present" if (root / "scripts/gauntlet_autopilot.py").is_file() else "not-present"
    results["visual_router"] = "source-present" if (root / "docs/CREATIVE_TOOLCHAIN.md").is_file() else "not-present-in-this-checkout"
    results["godot_project"] = "source-present" if (root / "project.godot").is_file() else "not-present"
    return results


def report(intent: str, registry: dict[str, Any], state: dict[str, Any],
           root: Path, override: str | None = None) -> dict[str, Any]:
    mode = parse_mode(intent)
    chosen = route_for(intent, registry, state["active"], override)
    git = git_info(root)
    recorded_sha = state["active"].get("last_observed_sha") or state["active"].get("last_verified_sha", "")
    stale = bool(recorded_sha and git["sha"] != recorded_sha)
    warnings: list[str] = []
    if stale:
        warnings.append("HANDOFF STALE: recorded SHA differs from local HEAD; reconcile branch/PR/CI before changing anything")
    if git["dirty"] == "yes":
        warnings.append("WORKTREE DIRTY: protect user edits and establish ownership before writing")
    if mode == "stuck":
        warnings.append("STUCK: inspect blocker and last failed approach, do not blindly repeat; change hypothesis or route")
    if mode == "handoff":
        warnings.append("HANDOFF: re-read approved design/current PR and capture exact SHA before trusting saved claims")
    if not state["active"]["evidence"]:
        warnings.append("No verified evidence linked in handoff; test/release status is NOT VERIFIED")
    incidents = state.get("incidents", {})
    repeats = [v for v in incidents.values() if isinstance(v, dict) and
               v.get("route") == chosen["id"] and v.get("failed_count", 0) >= 2]
    if repeats:
        warnings.append("DO NOT RETRY: same-route failure budget exhausted; choose fresh hypothesis/fingerprint or checkpoint blocker")
    return {
        "project": EXPECTED_REPO, "mode": mode, "entrypoint": registry["entrypoint"],
        "route": chosen["id"], "route_title": chosen["title"],
        "current": git, "saved": state["active"], "handoff_stale": stale,
        "route_exhausted_fingerprints": [v.get("fingerprint") for v in repeats],
        "tools": chosen["tools"], "checks": chosen["checks"],
        "required_artifacts": chosen["artifacts"], "constraints": chosen["requires"],
        "fallback": chosen["fallback"], "warnings": warnings,
        "next_actions": [
            "Read AGENTS.md, docs/ENGINEERING_ROUTER.md, current design and saved handoff",
            "Reconcile live branch/PR/CI and current worktree; never trust old summaries as live state",
            "Probe required tools, choose minimum relevant route and real source inputs",
            "Build in scoped branch, run actual checks and independent critic if authorized",
            "Checkpoint status, SHA, exact evidence, blockers, next_action; commit/publish before handoff",
        ],
    }


def checkpoint(root: Path, registry: dict[str, Any], args: argparse.Namespace) -> dict[str, Any]:
    current = read_json(root / "docs/handoff/ACTIVE_ROUTING_HANDOFF.json")
    problems = validate_state(current, registry)
    if problems:
        raise RouterError("; ".join(problems))
    ids = {r["id"] for r in registry["routes"]}
    if args.route not in ids:
        raise RouterError("route not in registry")
    if args.status == "blocked" and not args.blocker:
        raise RouterError("blocked checkpoint requires --blocker")
    if args.status == "verified" and not args.evidence:
        raise RouterError("verified checkpoint requires authentic --evidence")
    g = git_info(root)
    entry = {
        "task": args.task, "route": args.route, "status": args.status,
        "owner": args.owner, "next_action": args.next_action,
        "blockers": list(args.blocker or []), "evidence": list(args.evidence or []),
        "last_observed_sha": g["sha"] if g["sha"] != "NOT_VERIFIED" else "",
        "last_verified_sha": g["sha"] if args.status == "verified" and g["sha"] != "NOT_VERIFIED" else "",
        "branch": g["branch"], "updated_at": now(),
        "verification_note": args.verification_note or "NOT_VERIFIED until external evidence is reviewed",
    }
    next_state = {"schema_version": 1, "repository": EXPECTED_REPO, "active": entry,
                  "incidents": current.get("incidents", {})}
    errors = validate_state(next_state, registry)
    if errors:
        raise RouterError("; ".join(errors))
    write_atomic(root / "docs/handoff/ACTIVE_ROUTING_HANDOFF.json", next_state)
    return {
        "message": "Checkpoint written locally. Commit the handoff file to persist it for the next agent.",
        "checkpoint": entry,
    }



def record_incident(root: Path, registry: dict[str, Any], args: argparse.Namespace) -> dict[str, Any]:
    """Persistent anti-stall ledger: two identical failed attempts then DO NOT RETRY."""
    route_ids = {r["id"] for r in registry["routes"]}
    if args.route not in route_ids or not text(args.fingerprint) or not text(args.evidence):
        raise RouterError("route, fingerprint and real evidence reference required")
    if len(args.fingerprint) > 300 or len(args.evidence) > 1600:
        raise RouterError("fingerprint or evidence reference too long")
    state_path = root / "docs/handoff/ACTIVE_ROUTING_HANDOFF.json"
    state = read_json(state_path)
    problems = validate_state(state, registry)
    if problems:
        raise RouterError("; ".join(problems))
    records = state.setdefault("incidents", {})
    fingerprint = args.fingerprint.strip()
    key = hashlib.sha256((args.route + "\\n" + fingerprint).encode("utf-8")).hexdigest()
    entry = records.get(key, {
        "route": args.route, "fingerprint": fingerprint,
        "failed_count": 0, "resolved_count": 0, "last_evidence": "",
        "last_classification": "", "updated_at": "",
    })
    if args.outcome == "failed" and entry["failed_count"] >= 2:
        raise RouterError("DO NOT RETRY: identical route/hypothesis exhausted; change the route or fingerprint with new evidence")
    if args.outcome == "failed":
        entry["failed_count"] += 1
    else:
        entry["resolved_count"] += 1
        entry["failed_count"] = 0
    entry["last_evidence"] = args.evidence
    entry["last_classification"] = args.classification
    entry["updated_at"] = now()
    records[key] = entry
    if entry["failed_count"] >= 2:
        active = state["active"]
        active["status"] = "blocked"
        active["route"] = args.route
        marker = "DO NOT RETRY " + fingerprint
        if marker not in active["blockers"]:
            active["blockers"].append(marker)
        active["next_action"] = "Change hypothesis/route with new source evidence; do not repeat exhausted attempt"
    write_atomic(state_path, state)
    return {
        "message": "Incident recorded locally; commit/push handoff for future agent",
        "route": args.route, "fingerprint": fingerprint,
        "same_approach_failures": entry["failed_count"],
        "do_not_retry": entry["failed_count"] >= 2,
    }


def main(argv: list[str] | None = None, *, root: Path = ROOT) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    sub = parser.add_subparsers(dest="command", required=True)
    enter = sub.add_parser("enter", help="single entry for continue/stuck/new agent/new task")
    enter.add_argument("--intent", required=True)
    enter.add_argument("--route", default=None)
    sub.add_parser("audit", help="probe actual binary presence without inventing installations")
    sub.add_parser("validate", help="validate registry and handoff contract")
    sub.add_parser("handoff", help="recover and print canonical next agent briefing")
    incident = sub.add_parser("incident", help="record bounded failed approach and require a changed hypothesis")
    incident.add_argument("--route", required=True)
    incident.add_argument("--fingerprint", required=True,
                          help="short stable description of SAME input, route and hypothesis")
    incident.add_argument("--outcome", choices=["failed", "resolved"], required=True)
    incident.add_argument("--evidence", required=True, help="real CI/log/source evidence reference")
    incident.add_argument("--classification", default="unclassified")
    cp = sub.add_parser("checkpoint", help="write atomic trackable handoff state (no commit)")
    cp.add_argument("--task", required=True)
    cp.add_argument("--route", required=True)
    cp.add_argument("--status", choices=sorted(STATUSES), required=True)
    cp.add_argument("--owner", required=True)
    cp.add_argument("--next-action", required=True)
    cp.add_argument("--blocker", action="append", default=[])
    cp.add_argument("--evidence", action="append", default=[])
    cp.add_argument("--verification-note", default="")
    args = parser.parse_args(argv)
    try:
        reg = load_registry(root)
        state = read_json(root / "docs/handoff/ACTIVE_ROUTING_HANDOFF.json")
        failures = validate_state(state, reg)
        if failures:
            raise RouterError("; ".join(failures))
        if args.command == "validate":
            output = {"verdict": "PASS: contract only", "routes": len(reg["routes"]),
                      "handoff": "valid", "external_tool_execution": "NOT_VERIFIED"}
        elif args.command == "audit":
            output = {"repository": EXPECTED_REPO, "binaries": probe_tools(root),
                      "warning": "binary-found is not runtime/export/device verification; plugins not discoverable from CLI"}
        elif args.command == "checkpoint":
            output = checkpoint(root, reg, args)
        elif args.command == "incident":
            output = record_incident(root, reg, args)
        else:
            output = report(args.intent if args.command == "enter" else "передача новому агенту",
                            reg, state, root, getattr(args, "route", None))
        print(json.dumps(output, ensure_ascii=False, indent=2))
        return 0
    except RouterError as exc:
        print(json.dumps({"verdict": "FAIL", "reason": str(exc)}, ensure_ascii=False), file=sys.stderr)
        return 2


if __name__ == "__main__":
    raise SystemExit(main())
