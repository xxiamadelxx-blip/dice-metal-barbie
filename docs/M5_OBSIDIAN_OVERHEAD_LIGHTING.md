# Selected obsidian: overhead reflection correction, 2026-10-13

**Superseded visual verdict:** the user rejected these captures as low quality
later on 2026-10-13. See `M5_VISUAL_REJECTION_2026-10-13.md`. This experiment is
not an approved improvement or a template for the remaining dice.

The original selected D20 GLB, baked maps and darker gold are unchanged, as is
the original studio HDR file. Their SHA256 values still match the pinned
private inputs in `src/assets/approved_m5/README.md`. No Blender geometry,
material color, emission, camera, collider, mass, result formula or RNG was edited.

The previous overhead game captures lost nearly all stone shading outside
the narrow reflected strips. Eight HDR rotations failed to solve this across
the tested poses. Six uniform-fill values and four overhead-light values were
then compared using real Godot Mobile captures in the actual game camera.
The selected static sky shader adds neutral reflection fill 0.04 and broad
overhead reflection 0.12 to the original panorama. Higher fills made the
stone too grey and were rejected. The panorama remains hidden behind the
original game background; the physical scene and directional lights stay fixed.

The shader has no time, camera-position or moving-light input. Godot's static
radiance workflow is described in the [official sky shader documentation](https://docs.godotengine.org/en/4.6/tutorials/shaders/shader_reference/sky_shader.html).
Actual Mobile/Vulkan compilation was exercised locally; this does not prove
Android inclusion or phone performance.

## Evidence and critique

- `tests/m5_selected_obsidian_lighting.gd` completed with exit 0: 120 original
  720×1280 screenshots, all 20 faces × three yaws × original/corrected light.
  These are explicitly frozen staged comparisons, not physically rolled outcomes.
- Every pose's canonical top value matched its face label; overhead camera
  transform and size stayed unchanged. Imported GLB materials remain unoverridden.
- In the central 24-pixel-radius region, median stone luminance changed from
  0 to 18/255; gold-hue pixel median changed from 115.84 to 123.98/255.
  These are pixel measurements, not OCR, human readability or premium-art scores.
- Actual main-scene Jolt throw: D20=13; genuine simultaneous mixed throw
  D20=6 + D6=1 = 7, no failed checks. Collider points, original mass 0.045
  and overhead camera preserved. Full 183-frame fixed-step 24fps movie retained.
- Fresh eight-mode live capture: D4=4, D6=4, D8=3, D12=4, D20=20, D10=5,
  single D100=64 and two-D10 D100=55. All completed. 1,325 decoded frames
  processed sequentially, zero black frames after GO. D20's genuine natural-20
  gold aura is visible in the original footage.
- The D20 frame-25 duplicate warning remains. The first visible D20 follows
  the previous settled D12; the interval is start/render delay before visible
  launch. Original frame sheets around the warning are retained. Software
  rendering measured 8.59–10.66 fps; nominal 24fps video is not unique-frame
  throughput and not OnePlus Nord 3 performance.
- To avoid older leftover frame sheets from a reused directory, current raw
  videos and timeline receipts were copied into a fresh evidence directory
  and the full auditor rerun there. The package uses only that fresh directory.
- Fresh headless checks: D20 geometry, M4 formulas, critical aura, selected
  engraved assets, physical pool and real reroll all exit 0. Router contracts
  24/24 and Gauntlet contracts 25/25 passed; architecture/security static gates pass.

Self-review of matched-pose and real-roll captures finds the stone contours
more consistent while retaining neutral black polished surfaces and the
selected gold. Some small or oblique numerals remain dim at the current game
scale. This is an incremental lighting improvement, not M5 artistic acceptance.
Other dice still use their existing assets. Android/AVD with these exact private
inputs and real Nord 3 readability/performance remain NOT_VERIFIED.

## Actual independent critic triage

[Canonical run #38379371567](https://github.com/xxiamadelxx-blip/dice-metal-barbie/actions/runs/38379371567)
produced the actual `qwen2.5-coder:7b` response at preceding source
`d949b9b77ca693fb65d40b4e291fdd23b203a7e1`; raw artifact
`engineering-entry-and-qwen` id `11803031772` was downloaded and read.
The report says REVIEW_RECEIVED with the matching SHA. Qwen discussed Docker
routing and successful tests, but gave no ranked concrete defect or visual
evaluation. Triage: no actionable finding; review coverage is limited. This
is evidence that the critic executed, not a visual PASS or a review of this
new lighting revision. The new shader and staged regression are included in
the canonical source-review paths for the next exact-commit CI run.

Keep PR #23 draft. Next: inspect the new commit's actual model response,
test the exact private-input Android build, then apply the selected stone
material to the remaining authored dice with their canonical face maps preserved.
