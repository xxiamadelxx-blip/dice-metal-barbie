# Matt Shumer-inspired Gauntlet Loop: operational procedure

After M0 and M1 approval:
1. **LEAD:** describe objective, approved reference, artifact and measurable acceptance criteria.
2. **BUILDER:** deliver actual code/model/scene/test/APK.
3. **CRITIC:** independent reviewer if available, **fresh context**, only artifact/tests/references, no builder justification. Otherwise use automated checks plus transparent self-review, mark independence NOT VERIFIED.
4. **COMPARISON:** factual PASS / FAIL / NOT VERIFIED per criterion. Fail includes reproducible defects.
5. **FIX → REPEAT:** fix highest-impact root cause, rerun checks, reevaluate; no artificial three-iteration cap. Stop/report if objective blocker or diminishing progress.
6. **SMOOTHING:** check full app consistency, UI, audio, states, physics, persistence and performance; run regressions.

For each substantial PR, include: scope, reference, exact tested commit, commands/results, links to Actions logs and artifacts, user-device evidence if present, critic status, unresolved blockers. An unrun test MUST be NOT VERIFIED, never PASS. A successful compile alone cannot pass an app milestone.

Validation levels:
- Numeric: test oracle, boundary and chi-square tests; no claim of absolute randomness.
- Physics: real bodies, collisions, deterministic scenario playback, movement bounds, visual face mapping.
- Visual: actual captured video/screenshot compared with approved design; don't grade a mockup as a running screenshot.
- Android: successful CI export, actual installation and later stable-key update test.


## Persistent autonomous critic mode
The user's instruction is to let the loop replace manual iteration feedback. The BUILDER must not request another go-ahead for each visual improvement. Each pass evaluates the *running engine artifact*, identifies the most consequential defect, implements a correction and repeats CI. A GREEN build is never automatic artistic acceptance. The independent critic label is reserved for a genuinely separate reviewer; deterministic automated contrast heuristics and first-party image inspection are declared as such.

Mandatory result matrix, maintained in PR for each iteration:
| Gate | Result | Evidence |
| --- | --- | --- |
| Engine import / scripting | PASS / FAIL / NOT VERIFIED | CI log |
| Physics and face numbering | PASS / FAIL / NOT VERIFIED | Jolt regression |
| Native visual composition | PASS / FAIL / NOT VERIFIED | exact captured PNG and specific critique |
| Android build & signature | PASS / FAIL / NOT VERIFIED | build artifact/signature |
| On-phone readability/performance | PASS / FAIL / NOT VERIFIED | handset test, never guessed |

If a renderer artifact is available, compare it to the previous artifact, capture an explicit remaining-defects list, and do not mark art accepted merely because a pixel/contrast smoke test passes.

## Tool-specific autonomous critique
Choose minimum viable tool from `docs/CREATIVE_TOOLCHAIN.md` and collect direct evidence of its executable/capability. A successful apt install is NOT headless support. Model gate: watertightness/bounds/face index + glTF import; material gate: color space, texture channels, seam and macro crop; UI gate: screenshot/hit targets; video gate: genuine Godot-captured frames; APK gate: ARM64/export/signature and later on-device install. Reject misleading claims even if the build exits 0. If a newly tried optional editor fails, record the failure and use the documented fallback without blocking the entire project.

## 24fps temporal critic: user-mandated full-throw evidence
For each type D4/D6/D8/D12/D20 use `tests/temporal_roll_capture.gd` to orchestrate one real Godot/Jolt physical throw under `tools/visual/run_temporal_capture.sh` with FFmpeg X11 screen recording, nominal **24fps**. A READY/GO/DONE handshake starts screen capture before each throw and records physical result with elapsed seconds. `tools/visual/audit_roll_sequence.py` reads **every decoded 720x1280 frame sequentially**, compares to the previous, and saves a per-frame JSONL timeline. Detect lack of movement, repeated frames, screen blackouts and transitions; keep complete videos, contact sheets and result timing. When anomalies occur, inspect their timestamps in context and correct implementation before recording again. The workflow is native Mesa, not an Android emulator. Mark emulator/FPS/phone results NOT VERIFIED until a genuine AVD/phone capture is added. Automated frame metrics do not equal human semantic understanding of every pixel.

### Temporal Gauntlet first execution: false PASS corrected
[First five physical-throw screen-recordings #38083902758](https://github.com/xxiamadelxx-blip/dice-metal-barbie/actions/runs/38083902758) decoded **550 frames** across five real D4=3, D6=5, D8=4, D12=7, D20=12 rolls. Visual critic examined D20 contact sheet and confirmed the last **five screens turned completely black after the game window closed**, which initial script flagged as anomalies but incorrectly returned PASS. Root cause was missing FFmpeg→Godot finalization acknowledgement. New `saved-D*` handshake prevents closing/switching views until the prior video is fully finalized. The frame auditor now **fails** on ANY black scene frame after the GO transition, rather than merely reporting it. Measured native renderer throughput under software llvmpipe ~10–17 distinct drawn frames/s; report now explicitly states actual measured engine throughput per throw and does not mislabel a 24fps file as smooth 24fps gameplay. Native software rendering is not Android hardware performance.

### Visually inspect every second at 24-frame granularity
Besides 24fps MP4 and complete JSONL, the temporal runner writes `ALL-24-frames-D<die>-second-<n>.jpg` where ALL 24 consecutive screenshots of a full second are presented in order. This gives the autonomous critic visually traversable one-second strips without selecting only representative keyframes. Spot-check all strips for snapping, disappearance, wrong size/scale, occlusion and UI changes; if unusual, open adjacent video frames and correct the source. Automated frame math is supplemental, not independent semantic reading.
