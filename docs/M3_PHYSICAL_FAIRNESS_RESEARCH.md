# M3 long-running genuine Jolt fairness research

Purpose: move beyond the ordinary 48-throw M3 reliability gate without
making every PR-triggered Gauntlet wait 20–40 minutes. This experimental
workflow is intentionally separate; it is NOT release approval.

## Scope
- Read every result from a **real completed Jolt physical body**,
  compare upper kite normal, rigid-body result and visible HUD.
- Default 150 physical D10 + 200 genuine 100-faced D100 +
  100 physical dual-D10 percentile outcomes (450 operations).
- Report exact per-throw JSONL, face ids, settle time, recoveries, invalid
  stops, coarse 10-bucket grouped frequencies and chi-square per mode.
- Run `.github/workflows/m3-longrun-fairness.yml` on branch
  `qa/m3-jolt-fairness` or manually select a source revision.
- A grouped ten-bucket statistic with ~20 expected per group for D100 may
  detect **large** physical biases, but cannot prove equal probabilities
  for each of all 100 faces. No claims of absolute uniformity.
- Confidence bound for zero failures over N completed operations:
  one-sided upper 95% limit = `1 - 0.05**(1/N)`. For N=450 the
  upper bound is ≈0.66% under independent identically distributed trials.
  The assumptions (particularly iid) remain independent-review questions.
- Full M3 release acceptance also requires existing 8-mode actual 24fps
  Gauntlet, Android AVD real frames, signed ARM64, and on-device QA.
- The strict approved M5 material/interface work is deferred until M4
  mechanisms are completed. No development order bypass.

Mandatory: no synthetic result assignment, forced face rotation, discarded
failures, invented FPS, or hiding problems behind a green CI mark.
