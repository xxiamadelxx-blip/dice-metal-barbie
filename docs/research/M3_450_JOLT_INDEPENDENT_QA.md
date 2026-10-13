# Independent QA: 450 true Godot/Jolt physical throws

**Date:** 2026-10-11. **M3 cloud QA:** testable technical evidence, NOT absolute proof of unbiased physical randomness. **Source:** [long-run Actions #38095307038](https://github.com/xxiamadelxx-blip/dice-metal-barbie/actions/runs/38095307038), commit `18f3d0f`, artifact `m3-longrun-jolt-physical-outcomes` (original per-throw JSONL and engine report). Main working PR #23 continues separately.

## Independent audit

An independent Python program reread all **450 actual** JSONL records, recomputed each outcome from logged physical top faces, checked complete trial indices, compared frequencies against Godot's saved histograms, and recomputed grouped chi-square. All checks passed, without creating or substituting any simulated result.

| Real physical mode | Completed | Distinct observed results | Maximum settlement | Ten-bin chi-square / 9 df | Approx. p under uniform 10 groups |
|---|---:|---:|---:|---:|---:|
| Single D10 | 150/150 | 10 / 10 | 4.158 s | 7.867 | 0.548 |
| Single 100-face D100 | 200/200 | 82 / 100 | 9.333 s | 9.800 | 0.367 |
| Two physical D10 / percentile | 100/100 | 65 / 100 | 4.242 s | 13.600 | 0.137 |

Engine self-report: **2,001 checks, 0 errors**, max bounded physical recovery impulses per mode: **1**. The correct failure-rate upper bound after zero failures in 450 *independent* trials is `1 - 0.05^(1/450) ≈ 0.006635` (0.66% at one-sided 95% confidence); independence has not itself been established.

**No scientific overclaim:** χ² with 10 aggregated groups cannot establish the probability of *each* 100-sided face; the physical samples are exploratory, not a lab certification. Independent D10/D100 uniformity in the target handset, long-run motor/temperature performance and actual 24 unique rendered frames/s remain UNVERIFIED. No actual observed series failure is discarded.

## Real-screen 24fps setlist from same accepted source

[Unified Gauntlet #38095490855](https://github.com/xxiamadelxx-blip/dice-metal-barbie/actions/runs/38095490855) passed the 8-source physical throw visual matrix, Android x86_64 emulator with Lavapipe and ARM64 debug APK. The exact completed Android artifact holds **3,539 sequential video frames / 151 ALL-24 contact sheets**, native Godot Mesa **1,042 frames / 46 ALL-24 contact sheets**, both with zero detected black frames; all 8 Android logs contain actual Jolt start and completion signals. Frame cadence is 24fps, **not** unique game render fps. Android software had extensive duplicate frames and transient first-launch overlay already corrected by real pixel evidence. Real-phone OnePlus Nord 3 is still NOT VERIFIED.

**Art critic:** Android end state shows small numbers and a nearly unreadable single D100. Overhead projection and true physics preserved, but this is M3 functional testbed, NOT premium Concept 3 approval. Full materials/textures/skin/editor architecture to be used at **M5**, as user-approved.

## Reproduction

- `tests/m3_physical_fairness_study.gd`: same production Jolt scene, genuine physical outcomes; 150 D10, 200 D100, 100 paired D10 default.
- `.github/workflows/m3-longrun-fairness.yml`: separate workflow in `qa/m3-jolt-fairness` to avoid blocking ordinary Gauntlet.
- `tools/visual/audit_m3_physical_evidence.py`: Python stdlib independent verifier of JSONL vs `study-report.json`, including upper-face map and buckets.
- Permanent summary here; raw original GitHub artifact may expire after configured retention (30 days). Re-run to collect fresh original evidence, not a synthetic replay.
