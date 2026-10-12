# M5 D20 premium obsidian: Blender-authored micro-normal -> GLB -> Godot Mobile and multi-yaw verification

**Date** 2026-10-12. **Scope** independent experimental D20 (NOT imported Codex's ready-made die). Geometry, 20 Boolean-cut gold numeral inserts, original face/value authority and 0.010 unit satin edge bevel preserved. **Technical PORTABILITY: PASS. Codex-class premium look: ART FAIL / NOT APPROVED.**

## Original evidence (actual renderers, not generated imagery)

1. [Blender-authoring + glTF contract and Cycles #38296322475](https://github.com/xxiamadelxx-blip/dice-metal-barbie/actions/runs/38296322475), [artifact 11768343964](https://github.com/xxiamadelxx-blip/dice-metal-barbie/actions/runs/38296322475/artifacts/11768343964), includes `authored.blend`, `roundtrip_import.blend`, exact `learned_d20.glb`, normal / ORM / albedo PNGs, `blender_cycles.png`, `godot_compatibility.png`, Godot Mobile camera frames and Blender / Godot logs. Export, actual embedded normal PNG pixels, PBR RGB and G roughness, real original geometry and Blender reimport and Compatibility/Mobile capture all passed. Job ended FAIL only on a subsequent **incorrect diagnostic assertion** of exactly two primitives; not a Blender/mesh/material corruption.
2. [Single GLB 3-angle Mobile F0 A/B #38303527219](https://github.com/xxiamadelxx-blip/dice-metal-barbie/actions/runs/38303527219), [artifact 11771493318](https://github.com/xxiamadelxx-blip/dice-metal-barbie/actions/runs/38303527219/artifacts/11771493318). PASS: real mobile screenshots for yaw 0/45/90, at specular knobs .50 and .25, using the actual normal map embedded in Blender GLB.
3. [Original GLB vs new Blender GLB same-camera/BRDF/yaw #38303606399](https://github.com/xxiamadelxx-blip/dice-metal-barbie/actions/runs/38303606399), [artifact 11771124304](https://github.com/xxiamadelxx-blip/dice-metal-barbie/actions/runs/38303606399/artifacts/11771124304). PASS: real 1000x850 Godot 4.6.3 Mobile Vulkan on desktop Mesa, yaw 0/45/90, matched HDR narrow50 and F0=.25. Contact `real_blender_normal_glb_rotation_ab.png`, full source frames, manifest and engine logs archived. Not real Android hardware.
4. [Existing original per-frame normal generated at runtime comparison #38295279142](https://github.com/xxiamadelxx-blip/dice-metal-barbie/actions/runs/38295279142), source/glb normal registration preserved separately; **not** proof of portable GLB.
 
## GLB geometry and PBR validation

- Original independently authored GLB SHA256: `ec7bcee05f9d6b571b1db0db4ebc09d726b1aedd53a53159c067032c7c74987f`.
- New genuinely Blender-authored tangent-space normal GLB SHA256: `f9c7fe2403878e06e5fd7cab71bf80e3d4c05a7334073e30d232e7c09b678589`.
- The independent ZIP-based glTF bufferView POSITION comparison found **4,454 exact shared unique positions at 5 decimal precision**, no old-only or new-only vertices. This does NOT prove fully equivalent indices/normals/tangents at all levels but does prove the spatial hull did not shift.
- Previous glTF `D20_Engraved_Obsidian` had two primitives: one face material + one chamfer material. New valid glTF has THREE primitives: one face material and TWO chamfer primitives with the same name `PolishedObsidian_EdgeSatin`. Physical geometry is unchanged; primitive count is an exporter/render partition, not necessarily number of distinct materials.
- Original Godot capture's `_review_materials()` correctly passed the new THREE primitives. A derivative `d20_micronormal_rotation_capture.gd` incorrectly required `get_surface_count()==2`, causing apparent failure. Fixed to demand **exactly one face primitive plus at least one satin chamfer primitive**, both PBR valid. Subsequent Godot logs explicitly report `D20_BRDF_PRIMITIVE_AUDIT faces=1 bevel_parts=2 total=3`; the previously failed assertion must NOT recur.
- The new Blender atlas implements slope `.12` in the 5-by-4 face UV tile space; changes tangent-space normals, not physical top-plane vertex heights. A real PNG is imported via glTF normalTexture. Source Blender Cycles render and later Mobile captures contain the same GLB normal pixels.
- Source AO is still neutral R=255 fallback; **spatial AO NOT VERIFIED**. Gold glyph punctuation 6/9, Jolt physics and actual 24fps motion NOT VERIFIED.

## Pairwise real image change (same Mobile scene / yaw / BRDF .25)

| Rotation | Mean absolute RGB pixel change in original diagnostic ROI [0..255] | P90 absolute change | Interpretation |
| --- | ---: | ---: | --- |
| 0° | 2.218 | 8.0 | New facet gradients visible, but strong flat silver facets remain |
| 45° | 2.167 | 7.0 | Small genuine difference with unchanged gold and face topology |
| 90° | 1.419 | 5.0 | Very subtle original-pixel differences |

Region x=250..779,y=155..724, includes some background; this is NOT a visual quality or fidelity score. Original before/after screenshots and SHA256 for all six raw PNGs are recorded in `real_glb_normal_rotation_evidence.json`.

**Artistic assessment:** the micro-normal map adds actual localized smooth reflections, especially on upper facets; also causes a visible diagonal/striped shading pattern. It does NOT solve the overall gray-plastic appearance or meet the Codex black obsidian standard. No owner art sign-off, no independent Qwen vision critic proof, no production skin acceptance. Thus **LEAVE BRDF / micronormal changes in isolated experiment**, no main/PR23 deployment.

## Next work and routing

Use the existing `creative-3d` + `qa-critic` routes, no extra router. Study the normal/TBN UV tile alignment and source of diagonal stripes in Cycles; investigate targeted studio-card direction/IOR physically rather than brightness hacks. Accept a successor only after true Cycles and Mobile side-by-side art review across multiple rotated frames, verified 6/9 recessed glyph fidelity and user approval. Subsequent separate gates: actual spatial AO, 24fps physical Jolt roll face mapping, Android AVD and actual OnePlus Nord3 performance/thermals. No claim of PS5 PSSR support and no unverified Godot Mobile SSR.
