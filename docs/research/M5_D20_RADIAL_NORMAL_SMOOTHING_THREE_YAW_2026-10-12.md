# M5: smooth radial D20 micronormal field, real Blender/GLB/Godot three-yaw A/B

**2026-10-12. Status: TECHNICAL PASS, artistic premium look FAIL / NOT APPROVED.** Isolated branch `experiment/m5-learn-codex-d20`. This is an independently generated Blender D20, not a direct copy of the owner's Codex model. No changes to `main` or PR #23.

## Reproducible underlying issue and fix

Previous authored tangent normal atlas used `ramp = clip(min(u,1-u,v,1-v)*4,0,1)`. The nearest-edge `min()` function is continuous but its first derivative changes abruptly along UV tile diagonals, creating visible directional streaks on shiny face planes. The new `tools/blender/d20_micronormal_field.py` replaces this with a centered circular compact-support field of radius 0.49, radial slope 0.18, neutral (0,0,1) tangent normals at each tile boundary, and continuously fading first derivatives. This changes the *tangent normal PNG*, not 3D vertices, gold inserts, boolean numeral engraving or the satin bevel profile.

At the specific u=v=0.16 probe with h=0.001, a finite-difference normalized first-derivative crease metric decreased from **0.32736 to 0.001772** (about 185x). It is a mathematical continuity metric, **not** a visual quality score. Four numeric regression tests passed: seam neutrality, finite/unit vectors and pixel variation, no diagonal derivative cusp, rotational symmetry and integrable/curl-free field. Runner command: `python3 -m unittest discover -s tests -p test_d20_micronormal_field.py -v`.

## Actual source GLB and engine evidence

- Old striped tangent-normal GLB SHA256 `f9c7fe2403878e06e5fd7cab71bf80e3d4c05a7334073e30d232e7c09b678589`.
- New C1-soft radial GLB SHA256 `e83e2aa139752ad5640b09f6404c205742937ad24c3b7c35a8946ad7ebdb3431`.
- **4,454 identical unique mesh POSITION coordinates (rounded to 5 decimals)**, no old-only or new-only vertices. The old glTF had one face primitive and *two* chamfer primitives; the radial GLB has one face and *one* chamfer. Both use the correct physical PBR materials. This split/merge is valid glTF, not geometry damage. This does **not** prove every index, tangent, UV or triangulation unchanged.
- [Blender source + GLB roundtrip + Cycles + real Godot Compatibility/Mobile #38305802712](https://github.com/xxiamadelxx-blip/dice-metal-barbie/actions/runs/38305802712): **SUCCESS**. [Real GLB, authored .blend, roundtrip .blend, normal/albedo/ORM PNG and source captures (artifact 11772617772)](https://github.com/xxiamadelxx-blip/dice-metal-barbie/actions/runs/38305802712/artifacts/11772617772).
- [Old striped vs new radial exact-source Godot Mobile 0°/45°/90° #38306809305](https://github.com/xxiamadelxx-blip/dice-metal-barbie/actions/runs/38306809305): **SUCCESS**. [Real unretouched source frames, GLBs, contact sheet and per-image SHA256 manifest (artifact 11772698044)](https://github.com/xxiamadelxx-blip/dice-metal-barbie/actions/runs/38306809305/artifacts/11772698044). Contact file: `real_striped_vs_radial_three_yaw_ab.png`. Renderer is desktop llvmpipe/Mesa Godot 4.6.3 Mobile, **not Android AVD or Nord3 phone GPU**.

## Three-angle actual-pixel evidence

Matched scene, HDR/BRDF and angles. Each metric is mean absolute RGB difference on the diagnostic ROI x=250..779, y=155..724, on 0..255 scale. This ROI includes background, so it is not a quality score.

| Yaw | Mean absolute RGB old vs radial | P90 absolute difference |
| --- | ---: | ---: |
| 0° | 0.903 | 3 |
| 45° | 0.771 | 2 |
| 90° | 0.568 | 1 |

Original source screenshots differ for all three yaws and are hash-recorded. Cycles and Godot look *slightly* smoother, but gray/silver side faces, low-contrast stone and limited premium reflectance remain. The artistic change is modest. **Do not promote into the game or claim Codex-level quality.**

## CI failures investigated, without hiding any evidence

1. [#38305566640](https://github.com/xxiamadelxx-blip/dice-metal-barbie/actions/runs/38305566640) failed because Blender's `--python` did not add the script folder to `sys.path`; four math tests passed, but the module import failed. Fixed explicit path in [`0cc85d7`](https://github.com/xxiamadelxx-blip/dice-metal-barbie/commit/0cc85d7c06ff797138057b59ca3f0d828cae23a4), followed by successful Blender and Godot roundtrip.
2. [#38306520878](https://github.com/xxiamadelxx-blip/dice-metal-barbie/actions/runs/38306520878) incorrectly required *two* chamfer primitives, though the new valid GLB has one. Its independent geometric equality and Godot import had already passed. Corrected workflow to require exactly one face material plus at least one bevel material; [#38306809305](https://github.com/xxiamadelxx-blip/dice-metal-barbie/actions/runs/38306809305) succeeded for all three real yaw captures. Future comparisons must not hardcode incidental exporter primitive partitioning.

## Remaining gates / next action

**ART FAIL** remains: studio-card HDR orientation, intensity, coat/IOR and side reflectance require controlled A/B tests across Cycles and Mobile. Avoid fake painted highlights, unrealistic metallic obsidian or base-albedo darkening tricks. Test spatial AO **from saved pixels and glTF channels**, not Blender bake's in-memory `made` message: current glTF red AO remains verified neutral white, **not spatial AO**. Numeral 6/9 punctuation/inlay legibility, real physical Jolt face mapping and full 24fps motion, offline Android emulator gameplay and Nord3 performance remain NOT VERIFIED on this candidate. Independent Qwen vision critic and owner art approval NOT VERIFIED. Keep M5 open, separate from PR #23 and `main`.
