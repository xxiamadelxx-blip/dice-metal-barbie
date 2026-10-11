# Canonical Gauntlet Loop: acceptance overlay v2

**Status:** proposed concurrent-safe governance overlay. It extends, not replaces, [GAUNTLET_LOOP.md](GAUNTLET_LOOP.md) and the real Godot/Jolt/Blender release workflow present on the active PR branch. No change to product design, D4/D6/D8/D10/D12/D20/D100 physics, GUI, Blender asset generation, or build/signing configuration.

## Canonical execution contract

1. **LEAD** selects an already approved feature scope, reference design or D&D rule, concrete raw artifact, immutable base/candidate SHAs, numerical+visual acceptance criteria, and an explicit `required_gates` list *before* building.
2. **BUILDER** implements in its own isolated branch and freezes a candidate SHA. Other agents' branches, CI runs, PR drafts, gameplay data, and build artifacts are read-only. Reuse `gauntlet-release-gate.yml` when it exists on the active implementation branch; never duplicate its Blender/Godot/Android workflows merely to satisfy this acceptance overlay.
3. **INDEPENDENT CRITIC** is a genuinely separate reviewer/session, with only the approved criteria, candidate SHA, raw code/diff, original Godot screenshots/uncut recordings, Jolt outcome logs, APK/emulator output. It must explicitly document what it inspected and the reviewer-run provenance. Builder's report and test job names are not themselves a critic. No separately instantiated reviewer => `INDEPENDENCE NOT VERIFIED`, never independent PASS.
4. **COMPARISON** returns `PASS / FAIL / NOT_VERIFIED` for each required criterion, ranked findings with original artifact evidence. A 24fps container/video is NOT proof of 24 unique rendered frames/s; pixel checks do not equal semantic visual review; emulator != OnePlus Nord 3.
5. **FIX -> REPEAT**: take the highest-impact root cause, change code/assets or the test environment based on evidence, rerun targeted suites, freeze a new SHA, re-invoke fresh critic. Never repeat an identical failed route without new evidence; bound wasted retries. A failing gate cannot be hidden or downgraded to PASS.
6. **SMOOTH / INTEGRATE**: run same-source Blender/GLB hashes + Jolt regression + native continuous 24fps frame sequence + actual Android AVD UI where applicable, then Android handset/signature/upgrade and design signoff for a release. Only the project's owner/integrator decides promotion. CI never writes fixes, invents a second agent, or silently merges itself.

## Evidence protocol (machine-auditable, not a model)

Run using Python stdlib:

```bash
python -m unittest discover -s tests -p 'test_gauntlet_evidence.py' -v
python scripts/gauntlet_evidence.py qa/gauntlet/<task>.json \
  --expected-sha <EXACT_40_CHARACTER_COMMIT_SHA> \
  --repository xxiamadelxx-blip/dice-metal-barbie
```

Schema v1 top-level:
- `schema_version` numeric 1, `repository`, `task`, `builder_id`, `approved_reference`, `baseline_sha`, `candidate_sha`.
- `required_gates`: non-empty list of immutable acceptance gate names.
- `iterations`: ordered objects starting `index: 1`, each with `candidate_sha`, `artifact_refs`, `checks` as `{gate,status,evidence_ref}`, and `critic` as `{mode,reviewer_id,isolated_run_ref,raw_artifact_review_ref,verdict,findings}`.
- `findings` items: `{id,severity,disposition,evidence_ref}`; `resolved` must include `retest_ref`, `deferred` only for minor with `tracking_ref`. A failed previous pass requires a next iteration `change_ref`.

The validator rejects missing gates, unproven PASS, unfinished critical findings, same builder/reviewer identity, nonindependent final critic, skipped fix evidence, and commit mismatch. Exit `0` proves **only structural completeness**; it does not fetch/validate URLs, run Godot, judge every pixel, or provide a genuine independent model/session. Original artifacts must be opened by a separate critic. Never insert fake artifacts merely to obtain green JSON.

### Gate selection by scope

- Physics/numbering: live Jolt geometry, real bodies and top face mapping; for percentiles dual D10 source truth and D100 modes; repeatable boundary and fairness tests.
- UI/art: approved overhead framing, accessible tap areas, authored Blender GLB, material inspection, whole-roll temporal frames and actual Godot screenshot critique, not just render placeholders.
- Offline features: history persistence and restart, formula/reroll/state provenance, no account or network.
- Android: successful ARM64 export alone is only an APK build PASS; Android emulator screenshot, real handset OnePlus Nord 3 performance, release signing and upgrade must each be independently identified; unavailable => NOT_VERIFIED. Release cannot be accepted without device evidence.

### Concurrency contract

This file and `scripts/gauntlet_evidence.py` are isolated governance work. Do **not** mutate active PR #23 or its ongoing `gauntlet-release-gate.yml` automation. This document refers to features present in that PR as pending integration into main, not as merged functionality. Keep this separate PR in draft until current implementation is reconciled; compare current PR head before merge, preserve both lines of work and never force push. Existing CI may continue uninterrupted. The new contract self-test workflow only tests this validator and never claims to perform or replace the artistic/physical Gauntlet.
