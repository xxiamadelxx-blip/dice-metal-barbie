# M5 Gauntlet · actual Blender-to-Godot obsidian material transfer

Status: **M5 candidate, native/AVD acceptance PENDING** after the new material commit. The approved minimalist Concept 3 is the sole artistic authority; M4 physical-cloud functionality must not regress.

## Independently opened ORIGINAL evidence from the preceding PASS

- [Unified real tool-route #38174391709](https://github.com/xxiamadelxx-blip/dice-metal-barbie/actions/runs/38174391709): all nine native/Blender/Jolt/Android jobs PASS. Actual output [Blender asset artifact #11715486450](https://github.com/xxiamadelxx-blip/dice-metal-barbie/actions/runs/38174391709/artifacts/11715486450) contains five GLBs, five mesh-QA OBJ exports, three PBR maps, Inkscape-exported 256×256 glyph and `m5-route-manifest.json` SHA256 manifest. [Native Godot screenshots #11714694965](https://github.com/xxiamadelxx-blip/dice-metal-barbie/actions/runs/38174391709/artifacts/11714694965), including `native-01-launch.png` and `native-06-d20-detail.png`, are genuine Mesa running-scene frames, not Blender illustrations.
- Source visual review: Blender's `d20_boolean_preview.png` has differentiated sharply lit planes, chamfer specular and recessed gold numbers. The same mesh rendered by native Godot in `native-01-launch.png` appears visibly flatter and more uniform blue-grey. The original Godot material wrapper `src/visual/premium_finish.gd:_stone_pbr_for_glb` had diffuse ambient reflectivity with rough clearcoat and a large hardcoded emission tint, masking much of the authored light response. **The proposed cause is grounded in read source but its visual improvement is NOT VERIFIED until the new images are opened.**
- Source 720×1280 native `native-01-launch.png` coarse original per-object luma (includes shadows/background, therefore *diagnostic only*, not a design score): D20 ROI (125,178)-(324,364) p5≈29.7, p95≈83.8; D12 ROI (370,205)-(615,425) p5≈28.5, p95≈74.7; D6 ROI (120,451)-(355,673) p5≈28.7, p95≈78.8; D4 ROI (435,556)-(612,740) p5≈43.5, p95≈71.9. Future screenshots must be compared at the same viewpoint, not by claiming a metric automatically measures beauty.

## Minimal targeted M5 correction

1. Keep **all five Blender GLB albedo/roughness/normal maps** applied in Godot. Preserve texture channel settings and physical numbering metadata.
2. Remove uniform additive stone **emission wash**; set rough-texture multiplier 0.78, moderate physical metallic 0.18, clearcoat 0.60 and narrow 0.16 roughness. No changes to `src/dice/`, `src/core/`, collision shapes, masses or physical results.
3. Expand actual-Godot `tests/engraved_assets.gd`: require real GLB maps and *non-emissive* clearcoat material with bounded metallic/roughness. Run this inside the existing `godot-native-visual.yml` (not a script-only unit claim).
4. Re-run the **same-source** Blender/MeshLab/Inkscape output, Godot native launch/detail frames, complete Jolt/24fps video and original Android AVD/ARM64 Gauntlet. Use separate local Qwen 7B source critique if executed by workflow. Any red job or uninspected Android source remains NOT VERIFIED.

## Independent critic and next visual decision

The independent reviewer must open the two real native **and** corresponding Android captures, inspect die hue, shape/pocket legibility, actual shadow/highlight contrast and whether polished facets still look like obsidian rather than uniform slate. A numerical screenshot smoke score cannot replace this. If worse, roll back/adjust **visual material layer only** and repeat the full Gauntlet. The staged D20 1/20 VFX checks are *not* naturally rolled 1/20 evidence. Real OnePlus Nord 3 GPU, sound/haptics and M6 signing/release gates remain OPEN.

## Same-mesh Blender Cycles vs Godot Compatibility evidence, 2026-10-12

The owner's side-by-side original capture labels the right panel `GODOT 4.6.3 · COMPATIBILITY` / OpenGL; the configured shipped project uses Godot **Mobile**. It is valid evidence that visually identical imported geometry can show far darker faces, narrow harsh bevel highlights and harder contact shadows with different reflections and lighting. It is NOT an Android Mobile screenshot. Next real art Gauntlet must fix GLB/pose/exposure and isolate (1) environment/reflection, (2) imported roughness/clearcoat scalar, (3) gold import/light reach, (4) velvet directional nap, with actual Godot Mobile original PNGs. Do not confuse geometry AO offline PASS with runtime occlusion: the slot is still unintegrated. Native D4 `facet_dynamic_range=6.63` against minimum `8` remains FAIL on source `51612370a980`; AVD reroll drawer 0 changed pixels remains FAIL. Detailed original-evidence contract: [M5 action audit](research/M5_FREE_PREMIUM_MATERIALS_ACTIONABLE_AUDIT_2026-10-12.md).
