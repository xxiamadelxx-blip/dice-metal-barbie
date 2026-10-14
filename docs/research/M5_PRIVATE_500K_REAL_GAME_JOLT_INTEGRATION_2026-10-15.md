# M5: genuine selected 500K obsidian D20 integrated into real offline game/Jolt

**Date:** 2026-10-15. **Branch:** `experiment/m5-learn-codex-d20`. **Scope:** in-app native geometry/physics/value mapping **PASS within local desktop tests**. Approved artistic appearance, Android phone and final APK **NOT VERIFIED**. This is experimental opt-in only, and default app remains unchanged.

## Source integrity and actual implementation

- User-selected original BlenderKit `Procedural Obsidian` (diaverx miky), recovered user PRIVATE Library. Native Cycles-baked original selected source into real 2K tangent-space normal for **exact GLB SHA256 `60a7d624c126776eb357fb0ba97c8724175a5ec7ce629358276286da75889f39`**. Original signed-off style still pending.
- This is a **single, unique 500,000 triangle** glTF: **220,000 stone / 280,000 real raised/engraved gold / 20 gold meshes, 21 mesh parts**. No 1000-instance benchmark trick. Camera 90° overhead; Jolt physics controls roll.
- `src/dice/m5_original_obsidian_art.gd`: PRIVATE_SOURCE `res://src/assets/private/d20_selected_original_500k.glb`, **SHA256 fail-closed**, exact mesh/triangle/20-label gate, opt-in via `ProjectSettings.set_setting("dice/m5/use_private_d20", true)`. Disabled by default or missing/untrusted source => original low-poly D20 + original face results, unchanged. Never checked in private licensed binary.
- Imported GLB digit positions in local Godot coordinates do **not** have the same numbering/order/orientation as canonical `src/core/icosahedron.gd`. Fitted proper rigid `SO(3)` basis from all 20 original Gold_01..Gold_20 actual source mesh centers to canonical icosahedron normals, with 2.27° mean/3.36° maximum center angular error (glyph centering offsets). No mirror, determinant +1. Physical collision remains canonical convex hull 12 vertices, mesh visual scaled `0.895` to fit it. Face-index-to-printed-value mapping (0-based `Ico.FACES`):
  `[6,1,5,10,13,2,12,18,14,4,11,16,20,15,8,7,17,19,9,3]`.
  Every label 1..20 appears once; antipodal labels add up to 21.
- `src/dice/d20_body.gd`: attach real 500K scene to genuine `RigidBody3D` only when source matches; hide legacy visual and Label3D but **do not change the Jolt collision shape, throw impulse, solver, sleep condition or edge-recovery logic**; settled face computes actual *printed* value via above mapping. Exposes `top_visible_value()`. Gold alone receives per-mesh instance material override warm metal color (.92,.64,.27), metallic .55, roughness .29; **no source BlenderKit obsidian texture/material changes** and private GLB bytes remain original.
- `src/core/physical_roll_pool.gd`: uses `top_visible_value()` for D20 within advanced formulas and real physical rerolls; unchanged source-aligned `Ico.top_value` fallback for ordinary D20. No fake result injection.

## Real test evidence (all original logs inside PRIVATE Library QA ZIP)

**QA ZIP:** `/Дайс/D20_500K_PRIVATE_REAL_JOLT_IN_GAME_QA_2026-10-15.zip`. ZIP SHA256 `3458639b3d8c09ed1627268f71530cebc8f49a53cefb4b01e1553a6e61eeb01a`; compressed **14,150,064 bytes**, 24 original source/log/screenshot/manifest entries and README. Embedded original licensed GLB: **PRIVATE Library only**, never commit to public GitHub. Separate original screenshot 3-frame montage `/Дайс/REAL_500K_OWNER_OBSIDIAN_ACTUAL_APP_JOLT_3_FRAMES.png`. All images are actual original native Godot screenshots, not generative illustrations.

| Test | Actual observations | Status |
|---|---|---|
| Private original source GLB import and rig | SHA gate PASS; 20 gold numbers + stone 220k/280k; 12 original Jolt collider vertices | PASS |
| Static face mapping independent of artificial output | 20/20 original source printed labels matched physical canonical normals; all opposite pairs add to 21 | PASS |
| REAL Jolt source D20 repeated casts | **12/12 physical throws**, **167 total assertions**, no wrong face; user values actually observed: `20,10,18,19,11,12,3,5,10,20,6,15` | PASS |
| M4 mixed group `1d20+2d6` | Two real 3-body Jolt simultaneous rolls; real D20 alone rerolled once while both old D6 stayed unchanged; **26 assertions** | PASS |
| Old fallback original default D20 | Original test `tests/numbered_d20_physics.gd`: **8/8 casts**, **147 assertions**, no failures | PASS |
| SHA mismatch security fallback | Actual deliberate malformed private GLB at correct path; source rejected before import, original renderer/20 printed outcomes/Jolt hull preserved, original GLB restored exact SHA | PASS |
| **ACTUAL MAIN APPLICATION 720×1280** Godot Mobile/Vulkan | Native 4.6.3 Forward Mobile Vulkan 1.4.318 **Mesa llvmpipe desktop CPU**. Real 90° overhead UI, genuine source 500k Jolt in motion/settled original framebuffer PNG, physical outcome `17` = printed top `17` = UI `D20 / 17`; in-game felt contacts from Jolt logged | PASS only for this native platform |
| ReflectionProbe five hidden card studio in overhead app | Native Mobile image did **not** improve compared with control and slightly darkened face; **REJECTED**, not merged to public `src/main.gd` | REJECTED |
| Original selected studio HDR swap in overhead app | Same GLB/pose/camera A/B, original HDR had no useful improvement, slightly darkened die; **REJECTED**, not merged | REJECTED |
| Android emulator + physical OnePlus Nord3 memory/FPS/thermal / signing | No execution on phone or AVD with private art | NOT VERIFIED |
| Independent Qwen7B vision critic / owner original reference comparison | Not executed, **not artistically accepted** | NOT VERIFIED |

Raw headless native `godot --headless` harness generated known dummy rendering storage `material_get_instance_shader_parameters(material=null)` warnings on cleanup after dynamically loaded heavy source GLB, **no failed physical assertions**. Native actual Mobile/Vulkan main-app capture ran without that dummy-renderer error. This still warrants device/renderer cleanup review, not a claim of entire engine error-free QA.

A first physical Jolt lab test with incorrect artificial floor height `-0.90` (versus actual production physics felt floor `-0.04`) failed out-of-table limits. Corrected *test fixture floor* to same actual production height; **did not relax/change die out-of-bounds gate**. 12 subsequent actual-body natural rolls passed. CI source ZIP [#38646181029](https://github.com/xxiamadelxx-blip/dice-metal-barbie/actions/runs/38646181029) completed successfully; contains **public source only**, no source licensed materials.

## How to reproduce without leaking source

1. Retrieve private zip from personal Library, extract `models/d20_selected_original_500k.glb` **only on a local private workspace** to `res://src/assets/private/d20_selected_original_500k.glb`. Verify SHA above; never stage with public CI. Private source package also includes verified exact Godot gold/stone source material.
2. Use experimental branch source and set `ProjectSettings.set_setting("dice/m5/use_private_d20", true)` before loading `src/main.tscn`; otherwise default engine D20 must remain unchanged.
3. Execute tests from `tests/m5_private_original_500k_jolt_stress.gd`, `tests/m5_private_original_500k_mixed_pool.gd`, `tests/m5_private_bad_sha_fallback.gd` and `tests/m5_private_main_app_visual_capture.gd` (for latter, run **actual graphical Mobile renderer under Xvfb**, not `--headless`).
4. Note that bad-SHA fallback test must only be run on a deliberately corrupted temporary copy, with proper full source restored afterward. Never run it with the verified live source in place.

**Remaining goals:** genuinely premium black obsidian readable at approved mobile overhead camera (current in-game D20 looks small/dark); native 500k Jolt triple trials and M4 interactions proven in private tests, but Android APK integration, AVD/physical Android GPU throughput, source material license distribution review, independent image quality and owner art acceptance remain OPEN. Do not change main, Draft PR#23 or canonical fixed camera without approval.
