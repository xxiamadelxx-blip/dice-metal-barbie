# AGENTS — D&D 3D Dice

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
