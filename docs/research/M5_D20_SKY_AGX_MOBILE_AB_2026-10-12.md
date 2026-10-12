# M5 real D20: same-GLB studio ambient A/B and material surface audit
**Checked 2026-10-12, experimental art source 41d435c20ebc05e3e9847eb1c6bb26635ec6f875.** Scope is the user-authorized independently created D20 learning experiment, NOT importing Codex's actual GLB or changing D&D physics. Main and PR #23 unchanged. **M5 ART APPROVAL: FAIL / NOT YET ACCEPTED.**

## Direct original rendering evidence
- Source run: [https://github.com/xxiamadelxx-blip/dice-metal-barbie/actions/runs/38281898713](https://github.com/xxiamadelxx-blip/dice-metal-barbie/actions/runs/38281898713), green Blender+actual Godot 4.6.3/Mobile software-renderer pipeline. Artifact [#11762120818](https://github.com/xxiamadelxx-blip/dice-metal-barbie/actions/runs/38281898713/artifacts/11762120818), includes source `learned_d20.glb`, `authored.blend`, round-trip `roundtrip_import.blend`, authoring PNGs, both .hdr and all original Godot PNGs with logs.
- Distinct original captures from EXACT GLB SHA256 `ec7bcee05f9d6b571b1db0db4ebc09d726b1aedd53a53159c067032c7c74987f`: `blender_cycles.png`, `godot_compatibility.png`, `godot_mobile.png`, `godot_ibl.png`, `godot_ibl90.png`.
- Mesa software Vulkan **Mobile**, NOT Android / Nord 3. Snapshot camera/model/pose unchanged across Mobile variations. Actual `n.mesh.get_surface_count() = 2`: material 0 `PolishedObsidian`, material 1 `PolishedObsidian_EdgeSatin`. The original capture previously validated only surface 0; now both are actually visited and logged.
- Original GLB double-check: primary roughness **G ≈ 43.58/255 = .171**, base RGB `(23,25,28)`, neutral AO R=255 pending verified real spatial bake, metallic B=0. Material log `roughness=1.0` on face denotes Godot scalar paired with G roughness texture; do NOT erroneously claim effective .roughness=1.0. Face coat .26/.09, real edge .31 roughness, coat .05/.30. No raised rim permitted: previous corrected hull halfspace maximum error 4.47e-8.

## Three real Mobile A/B exposures on the SAME GLB
| Real capture | Studio settings | ROI luma mean 0..255 | ROI 90th percentile |
| --- | --- | ---: | ---: |
| `godot_mobile.png` | old COLOR ambient + ACES | 35.36 | 50.44 |
| `godot_ibl.png` | actual SKY ambient contribution=1 + AGX exposure=1.52 | **53.49** | **68.37** |
| `godot_ibl90.png` | same, rotate SKY 90 degrees | 53.62 | 66.37 |
| `blender_cycles.png` | author studio reference Cycles | 70.42 | 163.17 |

The luminance ROI is source PNG rectangular bounds x=220..789, y=160..709; may include background pixels, so it is a **relative diagnostic**, NOT specular fidelity or perceptual similarity score.

**Learning:** ambient COLOR with SKY contribution defaults can behave differently from intended fill; on this controlled GLB enabling Godot SKY + AGX had actual independent frame evidence of a ~51% ROI mean improvement. Rotating the shared HDR by 90 degrees does NOT solve the remaining specular problem. The user-provided Codex instruction also uses Godot sky ambient with exposure near 2^0.6, so this is directly actionable source-derived technique. Do not merely raise albedo/emission to hide a poor reflection pipeline.

## Next bounded actions
1. Keep `Sky + AGX` option as the experimental preview winner, **not yet game runtime**. Correct HDR coordinate-frame alignment (Blender +Z up versus Godot +Y up) and use studio reflections from broad real area lights; compare original PNGs before changing face PBR again.
2. On D20, improve real gold inset, 6/9 punctuation; independently test fixed .010 satin bevel and zero raised hull edge against any change.
3. Replace deliberately neutral R=255 AO with verifiable spatial ray-based geometry AO; currently cached `cycles_true_ao.png` still has invalid all-black pixels and `cycles_ao: made` is an **incorrect internal-state status**.
4. Only after owner is satisfied with D20 art, propagate approved finish to D6/D8/D10/D12/D4 and D100 behavior. Do not mutate Jolt face numbering, masses, collisions, result or 90-degree game camera.
5. Current project M4 Android source-reroll drawer acceptance remains open. No proof of Nord 3 install/FPS/thermals or final art signoff. Do not merge `main` or PR #23 on a green art CI alone.

**Independent art critic:** NOT_VERIFIED; this is a source-image inspection plus original pixel metrics, and cannot stand in for user acceptance.
