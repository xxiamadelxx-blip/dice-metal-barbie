# M5 source-grounded production audit: free premium D20 + velvet
**Audit date:** 2026-10-12. **Observed source:** `51612370a980e1355d897e84cdcd4503930f79c7` (PR #23, draft).
**Basis:** owner-provided `DICE_ROLLER_FREE_PREMIUM_MATERIALS_RESEARCH_PLAN.md` (PLAN / RESEARCH), approved Concept 3, canonical AGENTS/router/toolchain, exact-source GitHub Actions logs, and user-supplied Blender Cycles vs Godot 4.6.3 Compatibility comparison image.

> This is an actionable audit, NOT art approval or proof of real-device FPS. M4 is the active acceptance boundary; M5 is a feature-branch candidate. Do not merge into main or close issue #24 on documentation/CI smoke alone.

## Live evidence and non-negotiable facts
- PR #23 draft, main `5f9333cf4a4e8f1fe979b0c7498a30e33222f601`, source parent `51612370a980e1355d897e84cdcd4503930f79c7`.
- Exact-source [unified Gauntlet #38213538757](https://github.com/xxiamadelxx-blip/dice-metal-barbie/actions/runs/38213538757): **Blender/MeshLab source GLB production PASS**; five physically engraved models (D4/D6/D8/D12/D20), correct D20 5x4 primary UV0, actual GLB maps and SVG glyph asset via Inkscape. FFmpeg, ImageMagick and mesh QA were executed. Physical eight-mode temporal/Jolt capture PASS. Android regression job was still running at observation time; recheck before claiming result.
- **Geometry AO breakthrough, NOT Cycles AO:** `D20_GEOMETRY_AO_BAKED: rays=2012364 hit_fraction=0.01199 midtones=0.01054`; the previously failing `midtone_fraction > .008` content gate PASSED. Uses Blender BVHTree ray intersections against real Boolean-cut shell, not a procedural drawn AO image. Geometry AO is **NOT CONNECTED TO GODOT RUNTIME** (`runtime_ao=NOT_IN_GLTF_YET_IMPORT_TEST_REQUIRED`). The old Cycles headless bake failed; do not relabel this as successful Cycles AO.
- **Native visual FAIL:** D4 facet dynamic range `6.63` against unchanged minimum `8` in actual Godot 720x1280 original screenshot; D20 `37.0`, D12 `33.58`, D6 `38.72` passed this narrow pixel criterion. Source `tools/visual/critique_native.py`; machine contrast is not sufficient for art approval.
- **AVD UI FAIL:** source reroll drawer pixel difference `0`; `Actual Android source-reroll drawer is not visible`. Full-screen overlay/driver/late frame are hypotheses, not proven causes. Original screenshot artifacts retained in same run.
- Separate local **Qwen 7B** code critics ran in [#38213538413](https://github.com/xxiamadelxx-blip/dice-metal-barbie/actions/runs/38213538413) and [#38213538419](https://github.com/xxiamadelxx-blip/dice-metal-barbie/actions/runs/38213538419). Their successful execution is NOT a model-led visual review of the Blender/Godot comparison.
- Screenshot `BLENDER · CYCLES` vs `GODOT 4.6.3 · COMPATIBILITY` is **same GLB/camera, different lighting/render paths**, not proof of Godot Mobile or Android fidelity. Godot Compatibility/OpenGL and configured `project.godot` **Mobile** must not be conflated.

## Art critic: observed issues and falsifiable hypotheses
| Original-image observation | Probable domain (hypothesis, not verdict) | Isolated A/B test |
| --- | --- | --- |
| Cycles stone reads softer and more sculptural; Compatibility near-black facets and narrow blown metallic bevel streak | Environment, lighting shape, clearcoat/roughness, tonemapping mismatch | Frozen GLB/pose; isolate environment source, then roughness multiplier, then clearcoat; log settings + original PNG each time |
| Cycles contact shadow diffuse; Compatibility hard, wide dark polygon | Real light source type/size, shadow filtering and render path | Fix shadow configuration only, record actual engine support and frame cost |
| Velvet looks like a matte green mineral, not directional nap | Shader almost diffuse roughness .99, tiling, missing view-dependent fiber response | Separate albedo/fiber direction/high-frequency normal and compare at game size and during 24fps motion |
| D4 dark face contrast fails exact numeric gate | Light-to-face geometry and source reach, normals, imported material | One-variable actual Mobile key/rim repositioning; preserve unchanged pixel threshold and physical hull |
| Gold appears deep in Blender but looks dark on side planes | Gold BRDF with different reflected environment or import/material override | Audit Godot surface materials and light reach, compare same glyph macro without emission compensation |

### Renderer equivalence contract
1. Preserve source GLB, face number mapping, camera, scene pose, exposure and UI dimensions; save an original source frame per engine and SHA256.
2. Blender Cycles preview is **authoring reference**, Godot configured **Mobile renderer** is actual desktop integration target; Compatibility is optional diagnostics only; real ARM64 Nord 3 is device acceptance.
3. Verify real glTF slots and Godot `material_override`, color-space: Base Color sRGB, roughness/normal/AO as non-color, OpenGL tangent-space Y+ normals, G roughness / B metallic; avoid fake RGB-to-normal PBR.
4. D20 AO can be promoted only after valid Godot `occlusionTexture`/import path and A/B. A nonzero offline PNG with no runtime material slot is not a visible game improvement.
5. Prefer light/IBL/softbox reasoning; do not substitute emission wash for measured reflections. Capture macro + 720x1280 gameplay + 24fps continuous roll, check bright clipping and face legibility.
6. Do not overfit `critique_native.py` numeric acceptance: an independent art reviewer inspects ORIGINAL pixels against Concept 3. Human owner approval still required.

## Tool route: task-specific, 0 ₽
| Tool | Actual role / status | Do not claim |
| --- | --- | --- |
| Blender 4.x | REQUIRED: Boolean engraving, UV0, real GLBs, high/low if needed; actually executed in Gauntlet | Cycles AO success (failed historically) |
| Python NumPy/Pillow + ImageMagick | REQUIRED: repeatable PBR masks, UV/Gltf/gradient and channel audit; actually executed | histograms alone prove realistic AO |
| Godot 4.6.3 + Jolt | REQUIRED: real scene and physics, configured Mobile; source tests executed | Compatibility frame = Mobile/phone |
| MeshLab, Inkscape | Already executed for mesh QA / authored SVG raster where relevant | artistic quality from CLI exit code |
| FFmpeg/ffprobe | REQUIRED for motion: original roll sequence and per-frame JSONL | MP4 24fps implies 24 unique engine frames |
| Ollama Qwen 7B | Separate executed **code critic** on GitHub CPU runners | independent image-art critique |
| Material Maker, Krita, GIMP, OpenSCAD, Trimesh | CONDITIONALLY useful; install/CLI smoke varies; must prove actual task output first | a startup/version probe is production material acceptance |
| Figma/Canva/Adobe Express/to3D | Optional authorized UI/reference services, not needed for this D20+velvet slice | unverified connection, paid credits or ownership |
| ADB/AVD | Cloud emulator has real screenshots but the reroll UI gate is red | hardware GPU/temperature/FPS of Nord 3 |
No blanket launch of unrelated editors: the canonical router selects a tool by artifact need and evidence, per `docs/CREATIVE_TOOLCHAIN.md` and `docs/TOOLCHAIN_ARCHITECTURE.md`.

## M5 vertical-slice acceptance checklist (ART-00 to ART-05)
- [x] ART-00: exact PR/main HEAD and Blender/Godot/AVD logs inspected; prior unfinished gates preserved.
- [x] ART-01: D20 BVHTree ray-based geometry AO content gate passes and GLB UV0 atlas exists.
- [ ] ART-01: actual Godot runtime occlusion hookup and measured before/after **NOT VERIFIED**.
- [ ] ART-02: directional velvet fibers and low-noise normal/anti-tiling prove cloth at full scale and during contact.
- [ ] ART-03: D4 native facet numeric gate >=8 and source image aesthetic judgment pass; present value 6.63 FAIL.
- [ ] ART-03: Mobile screenshot lighting/reflectance A/B compared to Cycles reference. Uploaded Compatibility diagnostic does not suffice.
- [ ] ART-04: all seven approved physical types / paired D100 keep correct Jolt numbering and scene pose; do not silently stop at five GLBs.
- [x] ART-05: source exact-sha full throw 24fps continuous audit passes at this checkpoint.
- [ ] ART-05: AVD reroll source selector visible after action, no stale/UI frame substitution; current FAIL.
- [ ] ART-05: real Nord 3 perf FPS/frame pacing/RAM/heat, install/upgrade/offline, user art approval.
- [ ] G1: external assets/source licensing/provenance manifest checked if added; no paid dependencies.
- [ ] Final G1–G11 signoff from owner-provided free premium research plan; issue #24 remains open.

## Next bounded Gauntlet
1. Keep ART-01 geometric AO passing and upload original 1024² PNG/GLB manifest; inspect glyph-centered per-face spatial gradient in actual pixels. Avoid perturbing working source without a failed targeted test.
2. Repair single clear **D4 native lighting/facet** failure without lowering the numeric gate; capture D4 and D20 under the correct Mobile renderer.
3. Repair **AVD source-reroll drawer** using event/frame synchronization and original decoded screenshots; never accept only GDScript logs.
4. On green native+AVD source, create genuine A/B for D20 stone/velvet in Godot, then Android on a real Nord 3. Model/texture work must not alter collision, face IDs, masses, result, D100 behavior or 90° overhead camera.
5. Independent critic examines source *and* actual source PNGs, states PASS/FAIL/NOT_VERIFIED, stores evidence and committed checkpoint on PR; do not touch main until M4 and M5 explicitly accepted.

**Sources of truth:** [research supplied by user] `DICE_ROLLER_FREE_PREMIUM_MATERIALS_RESEARCH_PLAN.md` (PLAN, not completion), [M5 lookdev](../M5_D20_PBR_LOOKDEV.md), [PBR transfer](../M5_PBR_TRANSFER_GAUNTLET.md), [router](../ENGINEERING_ROUTER.md), [creative toolchain](../CREATIVE_TOOLCHAIN.md), [main Gauntlet](https://github.com/xxiamadelxx-blip/dice-metal-barbie/actions/runs/38213538757).
