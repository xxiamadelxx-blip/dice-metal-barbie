# Blender correction after the rejected D20

The rejected look now has a separately authored, private D20 candidate. This is a review asset, not M5 acceptance or the default production model. The original approved control remains unchanged; do not propagate this candidate to other dice before reviewing the actual engine evidence.

## Actual authoring and source

Blender 4.0.2 executed the new scripts; Godot 4.6.3 executed the actual main scene with Mobile/Vulkan/llvmpipe and Jolt. The canonical router entry was executed again after restoring the tools: both version probes PASS, 28 engineering contracts and 25 Gauntlet contracts PASS, static architecture/security gates PASS in their limited scope. Local Ollama is absent; its independent run is the existing GitHub Actions entry job.

Code: `3aa97f9988e2a8b3dbc0ed8dc76cba5e201bbca3`.

- Immutable original GLB: `4c04c1707e1ed0d59f5bee286525059d85cdec5668c2ce5969d968d3a18221df`.
- Immutable original HDR: `a816625569d497e3672d522357c8ae292b9ef947eb3ae1c80c00e33f76b6a971`.
- Geometry authoring output: `b48e27c85aa83e5810b6042a449a40e153a06195c3b83739894e3a14244b1c25`.
- Final polished GLB: `a02ce9a2ea6c38367eb5ea739c289ad4c1540ffe481a1a08886a73d3a1f6e2c9`.

`tools/blender/rework_selected_obsidian.py` reuses all 20 original gold solids, including the 6/9 bars, and makes actual Blender EXACT Boolean recesses. Outer bevel is 0.024 with five segments, gold depth 0.013, cavity rim 0.0018. The stone is manifold, with zero nonmanifold edges and maximum canonical-hull overshoot 1.05e-7 (floating-point tolerance). Its 58,092 triangles are heavier than the 20,146-triangle control; phone performance is not verified.

`rebake_selected_obsidian.py` reopens the licensed source .blend to run file-version migration and recreates its native Principled connections. A material-only append produced a flat normal map and was rejected. The original shared UV charts are inappropriate for a fresh tangent bake; this candidate has a unique Smart UV unwrap and an actual 2048x2048 Cycles source-material bake. The first stronger version looked too rough. Final black PBR uses roughness 0.09, wave strength 0.025/scale 5, noise strength 0.0007/scale 3, normal strength 0.2. Original gold constants are unchanged. There is no colored albedo insert, displacement or stone emission.

`render_selected_comparison.py` renders both GLBs in the original Blender scene with identical lights and camera. `tools/qa/obsidian_candidate_review.gd` records a staged macro, both sets of 20 poses, then genuine single and mixed throws in the actual app. `--roll-only` keeps the window fixed for Movie Maker recording. These scripts do not implement new physics.

## Concrete evidence

Final asset receipts have `failures: []` and the exact final GLB SHA:

- Staged comparison: control20 + candidate20 poses; canonical face mapping intact.
- Main-scene throws: D20=20, mixed D20=10 + D6=2, total12.
- Separate continuous video: D20=1, mixed D20=6 + D6=5, total11.
- Original mass0.045, canonical collider points, camera transform and orthographic size14.2 checked unchanged.
- Nine native geometry/pool regressions PASS. This does not substitute for a new eight-mode video Gauntlet or a fairness study.

The 720x1280 Movie Maker clip contains225 decoded frames/9.375s at fixed24fps. All ten chronological 24-frame storyboards were viewed by the builder; no whole-scene blackout or disappearing rolling body was observed. Startup idle-display frames, intentional result holds, and the original natural1 critical-failure aura are retained. Actual recording took3m50s on software Vulkan; the file rate is not phone FPS or real-time cloud throughput. MSAA4x is fixture-only, not a production-setting change. The independent visual verdict remains NOT_VERIFIED.

Persistent private PNG/model/evidence identifiers are recorded in the canonical routing handoff. The original Blender source, control GLB/HDR, final .blend/.glb, original-size screenshots, all face images, complete video audit, reproducible scripts and actual logs are in the private proof ZIP. No licensed binaries or extracted maps were added to public git.

## Actual Qwen response and triage

[Canonical run38464325751](https://github.com/xxiamadelxx-blip/dice-metal-barbie/actions/runs/38464325751), job115527365574, completed its executed entry successfully at exact code3aa97f. The repaired loopback Ollama API bounds output to512 tokens and rejects incomplete, token-limited, wrong-model or malformed replies. This live response completed normally with220 tokens. API-response SHA is `1124d4d6cfbad7e39381533e698919a5306439a8b1befb2ac7575680fb162407`.

Artifact11848351479, `engineering-entry-and-qwen`, was downloaded and its ZIP SHA verified: `617fe352086020457fb3c5f47f24f89bd0b9fc1b1b6e40084cc6a8b0698de616`. Raw Qwen verdict is **FAIL**, preserved unchanged. Its three claims were triaged against the actual source and real Blender CLI runs:

1. Invalid normal-strength raises an assertion: intentional fail-closed validation. Actual value2 exits1 before any output directory is created. REJECTED as a defect.
2. Other wave/noise arguments lack validation: contradicted by the bounds shown in Qwen's own excerpt. Actual wave-strength.3, noise-strength.06, wave-scale31 and noise-scale31 each exit1 without outputs. REJECTED.
3. Missing optional normal-strength uses0.2: this is the intended calibrated default, recorded in the successful final bake receipt. Required source/geometry arguments remain required. REJECTED.

No actionable findings remain in that reviewed excerpt. Do not rewrite the model's raw FAIL as model PASS. Its scope was the latest2344-character diff, not the whole new authoring implementation and not images. Full authoring source review, independent artifact critique, overall Gauntlet result and Nord3 acceptance remain open. The public CI does not possess the private selected/candidate files and cannot certify their appearance.

Next: review these actual PNGs against the user's approved original, inspect final-source full Gauntlet, broaden independent source critique, then integrate the chosen private candidate through the existing canonical visual boundary. Preserve the original controls, physics, numerical outcomes and offline behavior.
