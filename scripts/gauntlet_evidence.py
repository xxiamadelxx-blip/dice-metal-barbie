#!/usr/bin/env python3
"""Fail-closed Gauntlet evidence contract. Validates records, not external truth.

No model/API calls, PR writes, network requests, or automatic repair.
Exit 0: complete candidate contract; 2: incomplete/rejected; 64: bad CLI.
"""
from __future__ import annotations

import argparse
import json
import re
from pathlib import Path
from typing import Any

SHA = re.compile(r"^[a-fA-F0-9]{40}$")
STATUSES = {"PASS", "FAIL", "NOT_VERIFIED"}
SEVERITIES = {"blocker", "major", "minor"}
MODES = {"independent", "self_review", "automated"}


def _text(value: Any) -> bool:
    return isinstance(value, str) and bool(value.strip())


def _url(value: Any) -> bool:
    # Presence is only a pointer, NOT external verification of its target.
    return _text(value) and (value.startswith("https://") or value.startswith("artifact://"))


def evaluate(record: Any, *, expected_sha: str | None = None,
             expected_repository: str | None = None) -> list[str]:
    """Return all structural/acceptance failures; empty means contract passes.

    Independent identity and provenance are declared and MUST be checked against
    original reviewer output by a real reviewer before release.
    """
    errors: list[str] = []
    if not isinstance(record, dict):
        return ["root must be a JSON object"]
    if type(record.get("schema_version")) is not int or record["schema_version"] != 1:
        errors.append("schema_version must be integer 1")
    for field in ("repository", "task", "builder_id", "approved_reference"):
        if not _text(record.get(field)):
            errors.append(f"missing {field}")
    if expected_repository is not None and record.get("repository") != expected_repository:
        errors.append("repository does not match expected project")
    for field in ("baseline_sha", "candidate_sha"):
        if not _text(record.get(field)) or not SHA.fullmatch(record[field]):
            errors.append(f"{field} must be a full 40-character git SHA")
    if expected_sha is not None and record.get("candidate_sha") != expected_sha:
        errors.append("candidate_sha is not the explicitly checked commit")
    gates = record.get("required_gates")
    if not isinstance(gates, list) or not gates or any(not _text(g) for g in gates):
        errors.append("required_gates must be a nonempty list of names")
        gates = []
    elif len(gates) != len(set(gates)):
        errors.append("required_gates contains duplicates")
    iterations = record.get("iterations")
    if not isinstance(iterations, list) or not iterations:
        return errors + ["iterations must contain at least one recorded build/review cycle"]
    previous_failed = False
    outstanding: dict[str, str] = {}
    last = None
    for index, step in enumerate(iterations, start=1):
        if not isinstance(step, dict):
            errors.append(f"iteration {index} is not an object")
            continue
        label = f"iteration {index}"
        last = step
        if type(step.get("index")) is not int or step["index"] != index:
            errors.append(f"{label}: index must be contiguous from 1")
        if not _text(step.get("candidate_sha")) or not SHA.fullmatch(step["candidate_sha"]):
            errors.append(f"{label}: invalid candidate_sha")
        artifacts = step.get("artifact_refs")
        if not isinstance(artifacts, list) or not artifacts or not all(_url(ref) for ref in artifacts):
            errors.append(f"{label}: real artifact_refs are required")
            artifacts = []
        if previous_failed and not _url(step.get("change_ref")):
            errors.append(f"{label}: after failure require a concrete change_ref")
        checks = step.get("checks")
        seen: set[str] = set()
        if not isinstance(checks, list) or not checks:
            errors.append(f"{label}: checks must be recorded")
            checks = []
        for check in checks:
            if not isinstance(check, dict) or not _text(check.get("gate")):
                errors.append(f"{label}: check without gate")
                continue
            gate = check["gate"]
            if gate in seen:
                errors.append(f"{label}: duplicate gate {gate}")
            seen.add(gate)
            if gate not in gates:
                errors.append(f"{label}: unplanned gate {gate}")
            if check.get("status") not in STATUSES:
                errors.append(f"{label}: invalid status for {gate}")
            if check.get("status") != "NOT_VERIFIED" and not _url(check.get("evidence_ref")):
                errors.append(f"{label}: {gate} needs original test evidence")
        missing = set(gates) - seen
        if missing:
            errors.append(f"{label}: missing gates {sorted(missing)}")
        critic = step.get("critic")
        if not isinstance(critic, dict):
            errors.append(f"{label}: critic is required")
            previous_failed = True
            continue
        mode = critic.get("mode")
        if mode not in MODES:
            errors.append(f"{label}: invalid critic mode")
        if critic.get("verdict") not in STATUSES:
            errors.append(f"{label}: invalid critic verdict")
        if mode == "independent":
            if critic.get("reviewed_sha") != step.get("candidate_sha"):
                errors.append(f"{label}: independent reviewer did not attest the exact candidate_sha")
            if not _text(critic.get("reviewer_id")) or critic["reviewer_id"] == record.get("builder_id"):
                errors.append(f"{label}: reviewer identity must differ from builder")
            if not _url(critic.get("isolated_run_ref")):
                errors.append(f"{label}: missing independent reviewer run evidence")
            if not _url(critic.get("raw_artifact_review_ref")):
                errors.append(f"{label}: reviewer must show inspection of raw artifacts")
        findings = critic.get("findings")
        if not isinstance(findings, list):
            errors.append(f"{label}: findings must be a list (empty allowed)")
            findings = []
        for finding in findings:
            if not isinstance(finding, dict) or finding.get("severity") not in SEVERITIES:
                errors.append(f"{label}: invalid finding/severity")
                continue
            if not _text(finding.get("id")) or not _url(finding.get("evidence_ref")):
                errors.append(f"{label}: finding needs ID and observed evidence")
            disposition = finding.get("disposition")
            if disposition not in ("resolved", "open", "deferred"):
                errors.append(f"{label}: finding needs disposition")
            if disposition == "resolved" and not _url(finding.get("retest_ref")):
                errors.append(f"{label}: resolved finding needs retest_ref")
            if disposition == "deferred" and not _url(finding.get("tracking_ref")):
                errors.append(f"{label}: deferred finding needs tracking_ref")
            if finding.get("severity") in ("blocker", "major"):
                if disposition == "resolved":
                    outstanding.pop(finding.get("id"), None)
                elif _text(finding.get("id")):
                    outstanding[finding["id"]] = finding["severity"]
        any_failed = any(x.get("status") != "PASS" for x in checks if isinstance(x, dict))
        previous_failed = critic.get("verdict") != "PASS" or any_failed
    if not isinstance(last, dict):
        return errors + ["no valid final iteration"]
    for finding_id in sorted(outstanding):
        errors.append(f"unresolved blocker/major finding carried across iterations: {finding_id}")
    if last.get("candidate_sha") != record.get("candidate_sha"):
        errors.append("last iteration does not match candidate_sha")
    critic = last.get("critic") if isinstance(last.get("critic"), dict) else {}
    if critic.get("mode") != "independent":
        errors.append("final independent critique NOT VERIFIED; self-review is not release acceptance")
    if critic.get("verdict") != "PASS":
        errors.append("final critic verdict must be PASS")
    checks = last.get("checks") if isinstance(last.get("checks"), list) else []
    if any(not isinstance(x, dict) or x.get("status") != "PASS" for x in checks):
        errors.append("every final required gate must PASS")
    return errors


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("record", type=Path, help="JSON candidate evidence")
    parser.add_argument("--expected-sha", required=True, help="exact 40-character candidate commit")
    parser.add_argument("--repository", required=True, help="owner/repository")
    args = parser.parse_args()
    try:
        data = json.loads(args.record.read_text(encoding="utf-8"))
    except (OSError, UnicodeError, json.JSONDecodeError) as exc:
        print(f"FAIL: cannot read evidence: {exc}")
        return 2
    failures = evaluate(data, expected_sha=args.expected_sha, expected_repository=args.repository)
    if failures:
        print("FAIL / NOT VERIFIED: Gauntlet contract rejected")
        for problem in failures:
            print(f" - {problem}")
        return 2
    print("PASS: evidence contract structurally complete; original sources and reviewer isolation still require real-world verification")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
