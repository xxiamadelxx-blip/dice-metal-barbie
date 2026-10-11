# AGENTS — D&D 3D Dice

## Mandatory unified engineering entrypoint (all tasks and recovery)

For EVERY Dice coding, design, art, audio, security, architecture, performance, QA or release task, **and especially** when user says **«продолжай»**, **«завис»**, **«застрял»**, or asks to transfer to a **new agent**, use the **single canonical** `docs/ENGINEERING_ROUTER.md` and `config/engineering_routes.json` first.

1. Read `docs/handoff/ACTIVE_ROUTING_HANDOFF.json` and real current GitHub branch, PR, CI and accepted milestone (the saved state is a pointer, not necessarily current truth).
2. In an available terminal call `python3 scripts/engineering_router.py enter --intent "<literal user request>"`; for stuck work use `--intent "завис"`, for agent transfer call `python3 scripts/engineering_router.py handoff`. If no terminal is available, follow the same steps through GitHub repository reads and explicitly mark CLI `NOT_VERIFIED`.
3. Select only required route(s) and actually present tools; verify installation/execution/auth separately. Keep approved Godot/Jolt physics, offline Android and creative workflow from feature branch unchanged.
4. Run scope-matched tests + real artifact critique / **local** two-model independent Gauntlet when actually runnable. Never claim PASS for unrun checks, an absent external reviewer, or unavailable OnePlus Nord 3 hardware.
5. Before yielding, checkpoint exact task/route/SHAs/evidence/blockers/next action using `scripts/engineering_router.py checkpoint`, then **commit and push** the tracked `docs/handoff/ACTIVE_ROUTING_HANDOFF.json` to the relevant branch/PR. A local edit alone is NOT durable handoff.

Never create a competing agent runbook; update the canonical router, and preserve feature work. These rules apply from fresh sessions, not only the current chat.

Read `docs/CONTEXT.md`, `docs/PRD.md`, `docs/ARCHITECTURE.md`, and `docs/GAUNTLET_LOOP.md` before significant changes.

Product and architecture were approved 2026-10-10. Never rewrite approved product decisions (top-down orthographic view, offline, obsidian/velvet, visible face = outcome, D100 two modes) without user consent.

## Required Gauntlet Loop (M2 onward)

LEAD → BUILDER → INDEPENDENT CRITIC (when actually available) → COMPARISON → FIX → REPEAT → INTEGRATION.

- Define objective, a real artifact, measurable acceptance and an appropriate reference for every task.
- Run engine/tests/export as applicable. CI green is necessary, **not sufficient**.
- Critic must inspect actual implementation/results, not builder's narrative. When no separate critic is available, mark `NOT VERIFIED`, never counterfeit independence.
- Record evidence in PR/Issues; fix failures and rerun.
- Do not invent test pass, FPS, APK, device checks, security validations or completed features.
- Final release requires on-device Nord 3 installation, offline, face consistency, statistics, signing and upgrade testing.
- No paid tools, cloud runtime, account flows, or third-party assets without approval/license.

Use feature branches and PRs. Do not push unreviewed work directly to `main` unless explicitly authorized. Never commit signing keys or passwords.


## Local independent critic routing

The default Dice critic is **Ollama running on the GitHub Actions CPU runner**, not OpenRouter. See `docs/GAUNTLET_AUTOPILOT.md` and `.github/workflows/gauntlet-autopilot.yml`. Real role separation uses distinct local models and separate requests: `qwen2.5-coder:1.5b` builder vs `qwen2.5-coder:7b` critic. Do not ask the user for model API keys or re-enable `GAUNTLET_AI_TOKEN` in default workflows. Run independent critique only when it adds value and report `NOT_VERIFIED` on any model/container failure; preserve existing native tests.

## Existing PR #23 feature-specific Gauntlet and creative tool requirements (preserved)

Read `docs/CONTEXT.md`, `docs/PRD.md`, `docs/ARCHITECTURE.md`, and `docs/GAUNTLET_LOOP.md` before significant changes.

Product and architecture were approved 2026-10-10. Never rewrite approved product decisions (top-down orthographic view, offline, obsidian/velvet, visible face = outcome, D100 two modes) without user consent.

## Current execution order (user priority, 2026-10-11)
**Current feature milestone is M4, not M5.** M3 cloud physical Gauntlet and the 450-real-throw research passed; actual OnePlus Nord 3 hardware, 60 FPS and fine-grained 100-face uniformity remain explicitly OPEN for acceptance. Complete **M4 rules/formulas, genuine multi-body physical orchestration, offline history, presets and usable controls → M5 production art/UX/audio/haptics → M6 Android device signing/release**. Do not confuse cloud-only M3 PASS with a released phone APK. Some M5 visual experiments have already been committed and tested; they do **not** make M5 accepted or move the active milestone forward. When M3/M4 are active, defer non-blocking studio lighting, premium skins, material retouching and aesthetic critique cycles; do only minimal legibility/accessibility improvements that unblock functional QA. No art-only CI churn that displaces missing dice/mechanics.

The creative router in `docs/CREATIVE_TOOLCHAIN.md` remains mandatory **whenever relevant**: use Blender/MeshLab/ImageMagick for authored 3D geometry and assets, Godot/Jolt for real physics and interaction, FFmpeg/Python for authentic recording QA, optional editors only when their export capability is proven. Do not fake installed/used-tool claims, and do not hand-code production sculpting into GDScript to dodge the authored Blender asset contract. Full per-frame 24fps Gauntlet remains required for geometry/roll/UI changes. M5 premium look is a release prerequisite, so never claim M6 complete before M5 artistic acceptance; these priorities postpone polish until M5, **not** beyond release.

## Required Gauntlet Loop (M2 onward)

LEAD → BUILDER → INDEPENDENT CRITIC (when actually available) → COMPARISON → FIX → REPEAT → INTEGRATION.

- Define objective, a real artifact, measurable acceptance and an appropriate reference for every task.
- Run engine/tests/export as applicable. CI green is necessary, **not sufficient**.
- Critic must inspect actual implementation/results, not builder's narrative. When no separate critic is available, mark `NOT VERIFIED`, never counterfeit independence.
- Record evidence in PR/Issues; fix failures and rerun.
- Do not invent test pass, FPS, APK, device checks, security validations or completed features.
- Final release requires on-device Nord 3 installation, offline, face consistency, statistics, signing and upgrade testing.
- No paid tools, cloud runtime, account flows, or third-party assets without approval/license.

Use feature branches and PRs. Do not push unreviewed work directly to `main` unless explicitly authorized. Never commit signing keys or passwords.


## Autonomous Gauntlet mandate (user instruction 2026-10-10)
Apply the loop to **every implementation change**, including art, UI, automation and builds, without asking the user to act as an iterative critic. The agent must own the compare/fix/retest decisions and prioritize the approved concept and running artifact. For high-impact work, set acceptance before coding, inspect raw engine output and record concrete defects. If independent reviewers are unavailable, perform explicit adversarial self-review using actual screenshots/logs and mark independence unverified; never fabricate a second agent.
Do not gate ordinary iteration on user responses. Escalate only necessary approvals, missing secrets or actual handset actions that cannot be performed autonomously. Keep draft PRs unmerged until unresolved device/release gates have real evidence. If a specific test cannot be run, record NOT VERIFIED, not PASS.

## Creative toolchain router, mandatory on every feature (2026-10-10)
Read `docs/CREATIVE_TOOLCHAIN.md`, `docs/TOOLCHAIN_ARCHITECTURE.md`, and `docs/TOOL_INSTALL_AUDIT.md` before choosing visual tools. Do NOT run every editor blindly; route each task to the cheapest, confirmed tool by inputs/output, without disturbing Godot/Jolt mechanics.

1. **Blender + Python:** sculpt/bevel/engrave/UV/export authored 3D geometry; model truth = `.blend`/generator scripts + deterministic GLB. All sculpted art must pass `tools/blender/validate_glb.py`, in-game import and real screenshots. Blender is not a physics engine or an alternative runtime.
2. **Godot 4.6.3/Jolt:** only runtime authority for physics, face IDs, UI, VFX, offline functionality and ARM64 APK. Compare actual runtime captures against approved Concept 3; no artistic PASS from Blender mockups.
3. **OpenSCAD:** use only for precisely constrained parametric prototypes and dimensional sanity checks; approved D4/D6/D8/D12/D20 collision geometry remains canonical in Godot. **Inkscape:** SVG paths for logos, ornament and engraving templates; verify vector-to-mesh conversion in Blender.
4. **ImageMagick and Python (NumPy/Pillow):** deterministic masks, image transforms, atlas/PBR maps, channel packing and pixel QA. **FFmpeg:** inspect/convert real engine screen recordings and produce review clips; never fabricate gameplay evidence. **Trimesh:** programmatic topology, watertightness/mesh budget and bounds checks; not a renderer.
5. **Figma:** optional reviewable mobile UI/wireframes, then implement Godot Control scene manually and test actual Android. **Canva / Adobe Express:** optional ancillary static promo/menu assets only, never the authority on gameplay/geometry, subject to connected account, rights and export verification. **to3D:** optional image-to-3D concept exploration, not a substitute for accurate dice, number mapping or trusted offline production GLB.
6. **Material Maker:** if verified in a disposable Linux runner, author `.ptex` reusable procedural materials, export tested textures; otherwise Python/Blender fallback. **MeshLab:** if verified, QC/repair heavy scans or decimation candidates; preserve label/normal orientation and physics mesh invariants. **Krita:** if verified, paint/edit texture masks and hand-drawn 2D assets; batch/GUI capability must be demonstrated before automation. **GIMP:** if verified, photo/texture retouch and export; only automate when CLI/noninteractive/GUI test is proven.
7. At selection time inspect `docs/TOOL_INSTALL_AUDIT.md` and the most recent `creative-toolchain-probe` artifact. **Not installed**, **binary present**, **launch checked**, **headless export tested**, and **production verified** are different claims. Integrations are conditional: tool advertised != user account connected/authorized. No login loops, paid services or proprietary licenses.
8. Apply **Gauntlet Loop** to every tool-produced artifact: defined acceptance -> build -> real capture -> critic -> fix -> regression. User is not a manual QA bottleneck. Require proof of license/source, reproducible versions and deterministic conversion. Never install extra tools in the Android app or require a PC. If a tool adds fragility, revert to the working CLI pipeline.

### Confirmed GitHub Ubuntu 24.04 tool-install results (runs #38075529457 / #38075709599)
All four optional editors installed on a disposable GitHub runner. GIMP `--version` works directly; Krita `--version` and MeshLab `-h` work **with `xvfb-run -a`**, not without DISPLAY. MeshLab also installs `meshlabserver`, but its no-DISPLAY invocation failed, so future batch conversions must be tested under Xvfb before use. Official Material Maker 1.7 checksum and executable `--version` succeeded with Xvfb; `.ptex` material export remains NOT VERIFIED. These are not installed on Android. Record invocation evidence per asset; avoid claiming GUI smoke = finished export.

## Continuous 24fps Gauntlet requirement (user-approved 2026-10-10)
Every change touching roll animation, dice geometry, camera, HUD or physics must be reviewed as a **full continuous 24-frame/sec temporal sequence per D4, D6, D8, D10, D12, D20, single D100 and D100_PAIR roll**, not sparse start/middle/end stills. [Temporal workflow](.github/workflows/temporal-roll-24fps.yml) performs *real* Jolt throws in a live Godot/Mesa/Xvfb scene, FFmpeg records each whole throw, and `audit_roll_sequence.py` decodes and tests **every frame in chronological order**, writing one JSONL line per image with timestamp, pixel changes, repeated-frame count and darkness/lighting anomalies. Review video and flagged intervals and rerun when failing. The mandatory checklisted eight-mode acceptance is in `docs/QA_M3_FRAME_SETLIST.md`, including both independently moving D10 bodies and real face/HUD agreement. Target recording rate of 24 fps does not imply 24 distinct engine renders per second. Contact sheets are only visual indexes; videos contain the full capture. **Do not claim the Linux window is Android emulator or that every frame was subjectively reviewed by a separate model**; real emulator/device is a separate acceptance gate.

### Explicit ALL-FRAME contact sheets
The temporal auditor must publish not only a sampled overview: save `ALL-24-frames-D*-second-*.jpg`, **24 real consecutive screenshots for each recorded video second**. The self-reviewer reads the timestamped sheets and can open full MP4 and JSONL around flagged details. Every decoded frame is still independently audited in code; a sheet is a presentation of the same raw frames, not a substitute for the actual recording. Do not imply automatic image statistics provide semantic interpretation of every event.

## Single-run GitHub Actions rule (user instruction 2026-10-11)
**Stop repetitive GitHub Actions status polling.** The canonical PR pipeline is `.github/workflows/gauntlet-release-gate.yml`: regenerate five GLBs from current Blender scripts, verify meshes and texturing, then pass those EXACT SHA256-tested GLBs to separate Godot-native visual, full 24fps temporal and Jolt/ARM64 jobs in the **same workflow run**. Only when all pass, pin the tested assets to the feature branch; create a single persistent GitHub Step Summary. Old independent workflows are manually dispatched diagnostic tools only; normal main push still runs unit/export CI. A bot commit does not start another CI run and should not need to: all generated bytes have already been tested via same-run artifact download. Never loop through `fetch_workflow_run_jobs` waiting for progress. One optional finished-result check is enough if required; continue productive work instead of repeatedly querying statuses. A failing pipeline is evidence to fix source and rerun on a NEW commit, not a reason to spam rechecks. Preserve user-approved full-frame/24fps checks and physics integrity. This CI coordinates tests and artifacts; it does **not** autonomously repair arbitrary defects or prove OnePlus Nord 3 performance.
