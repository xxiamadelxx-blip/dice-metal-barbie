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

## Anti-hang workflow, one asynchronous GH run (2026-10-11)
The user's repeated `Завис` reports pinpointed a design defect: Blender bot commits carried new GLBs into the PR while separate Godot/Android jobs were already running against old binary files. Repeated polling of `fetch_workflow_run_jobs` could never guarantee source/artifact consistency. `.github/workflows/gauntlet-release-gate.yml` now composes existing reusable workflows with `needs` dependencies, same-run `actions/upload-artifact`/`download-artifact`, SHA256 verification before import, a write-guarded final pin only if all required tests passed, and one always-present GitHub Step Summary. Parallel native capture, all-frame 24fps video and signed APK each use identical freshly sculpted GLBs. `concurrency.cancel-in-progress` cancels obsolete revisions to avoid burning repeated runners. Do not query the status endpoint over and over: Github is responsible for execution and final verdict. Subsequent code/art Gauntlet loops are driven by a concrete failed gate, not identical restarts. A GitHub CI runner is a verifier, not a self-editing autonomous agent; any actual correction must be implemented by the agent with evidence on a later commit. Linux Mesa is not a user's physical Android handset.

## Android AVD driver isolation (2026-10-11)
The first true x86_64 Android 35 Pixel 6 emulator with `-gpu swiftshader_indirect` installed and started Godot but returned a uniformly dark image for 100 seconds; saved raw logcat confirms `SceneShaderGLES3: Program linking failed: Fragment shader active uniforms exceed GL_MAX_FRAGMENT_UNIFORM_VECTORS (261)`. This is a shader link/backend failure, **not** proof that the underlying Blender geometry or Jolt physics is black. Godot upstream issue #109550 describes the same SwiftShader signature and notes that the issue may be inside SwiftShader. Android Emulator 37 lists `swiftshader_indirect` as deprecated; the user-approved production ARM64 Mobile/Vulkan preset is deliberately unchanged.

The experimental Android AVD workflow now tests Mesa `-gpu lavapipe -feature -Vulkan` using exact same-run GLBs, an independent x86_64 Compatibility/OpenGL APK, launch/ready screenshots, complete Android screen recordings only after a genuinely nonblank app frame, and structured ADB error evidence on failure. It is called by the **single** PR Gauntlet and remains a **diagnostic gate**; AVD failure MUST appear in the final report, but does not counterfeit Linux/native success as Android success. Do not treat an AVD experiment as target OnePlus Nord 3 FPS/quality approval. If this backend remains black, use its real EGL/Godot logs to choose the next backend; never silently strip scene/physics features from the production APK.

### Android AVD 24fps false-PASS repair (2026-10-11)
[Actual Lavapipe run #38087667936](https://github.com/xxiamadelxx-blip/dice-metal-barbie/actions/runs/38087667936) **FIXED BLACK SCREEN**: Android 35 x86_64 launched the game with Mesa Lavapipe/OpenGL, real 720×1280 screenshot shows the four idle 3D dice, controls and velvet table, with no black frames in the 1450 decoded video images. **But the old temporal test returned a false PASS**: D8-labelled video had 263 effectively identical frames, still showing the settled D6 and its result; D20-labelled footage began while D12 was still rolling. Successful recording alone did not prove five correct Android UI-triggered throws.

Correction: the debug APK logs `DICE_QA_STARTED Dn`, `DICE_QA_COMPLETED Dn=value`, and `DICE_QA_FAILED Dn=...` directly from real Godot/Jolt signals, never fabricated numeric outcomes. AVD captures each die for up to 30s, requires exact matching start and completion before moving to another die, saves the final Android ADB screenshot and tagged log, and then audits every decoded frame. Any missing start/result, impossible numeric value, physical failure, whole-recording freeze, or black frame is a real FAIL. Sequential sheets now retain **all 24 consecutive frames per second** instead of only one screenshot each second. Independent HUD OCR and actual Android physical frame rate remain NOT VERIFIED.

The unified artifact pin job must wait for the AVD diagnostic to end before a bot commit, and the overall Gauntlet verdict is RED when AVD fails, even if native/GLB/ARM64 gates are green. No real Nord 3 claim.

## New M3 eight-mode screenshot-setlist (2026-10-11; acceptance pending live CI)
Extend the existing real FFmpeg/Xvfb/720x1280 24fps recorded Gauntlet from **5 to 8 actual full throws**: D4, D6, D8, D12, D20, D10, single 100-faced D100, and D100 from **two independently settling physical D10 bodies**. Each mode gets its own READY/GO/DONE/SAVED physical handshake, unbroken MP4, per-frame JSONL and every chronological 24-frame-per-second storyboard. D10/D100 native capture explicitly compares real `ShapeMath.top_value` with Jolt body and HUD results; percentile mode checks BOTH actual top faces and computes 00=100. A held/failed roll, missing file, blackout or inconclusive top-face test is FAIL; never fake a roll, short-cut 100 sided Jolt with RNG, skip frames, or claim 24 distinct GPU renders/sec. This is native Linux/Mesa evidence, not proof of Android smartphone FPS. **Must observe new CI logs and artifacts to call PASS.** Existing Android AVD five older shapes remain independent until new modes are accepted.
