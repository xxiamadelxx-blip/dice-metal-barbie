# M5 D20: physically aligned Blender/Godot HDR and studio-light critique

**Date:** 2026-10-12. **Task:** continue independently authored D20, never copy the Codex GLB. **Status:** native export and Godot real-frame proofs PASS; **premium obsidian artistic acceptance FAIL / NOT VERIFIED**. No changes to D&D/Jolt/M4, `main`, PR #23 or Android project.

## Source of truth and original evidence

- Source die: exact independent authored `learned_d20.glb` SHA256 `ec7bcee05f9d6b571b1db0db4ebc09d726b1aedd53a53159c067032c7c74987f`, built by `tools/blender/learn_codex_d20.py`; 20 real Boolean-engraved gold numbers. Original Blender Cycles source `blender_cycles.png` SHA256 `feda2a8c14a4b97a73b75bc303b3ad2bb4955d42e7e88d0fed39c2127462b551`.
- [Godot Mobile original/physically aligned HDR comparison #38285582615](https://github.com/xxiamadelxx-blip/dice-metal-barbie/actions/runs/38285582615); original artifact `11763053133`, [direct artifact](https://github.com/xxiamadelxx-blip/dice-metal-barbie/actions/runs/38285582615/artifacts/11763053133).
- [Godot Mobile narrow-card comparison #38286307673](https://github.com/xxiamadelxx-blip/dice-metal-barbie/actions/runs/38286307673); artifact `11764095434`.
- [OmniLight isolation #38286853449](https://github.com/xxiamadelxx-blip/dice-metal-barbie/actions/runs/38286853449); artifact `11763264274`.
- All three A/B runs completed SUCCESS on **Godot 4.6.3 Mobile Vulkan / llvmpipe Mesa desktop**; renderer, source GLB SHA, specific capture variants, all stone surface PBR material checks and original PNG hashes were recorded. NOT Android / OnePlus Nord 3, no release signoff.
- Each panel of `real_hdr_axis_card_and_omni_ab.png` comes from actual renderer PNGs. Pillow only placed captured pixels into a contact sheet; no image generator, simulated dice or retouching.

## Exact root cause: inconsistent 3D coordinate basis for studio HDR

Blender panorama maps `u_B=atan2(d_B.y,d_B.x)/(2π)`, with Z up. Godot sky GLSL source maps `u_G=atan2(d_G.x,-d_G.z)/(2π)`, with Y up. With physical export axes `(x,y,z)_B→(x,z,-y)_G`, the same physical radiance direction needs `u_B=(.25-u_G) mod 1`. The prior shared Radiance `.hdr` was transferred WITHOUT this mapping.

- `tools/visual/d20_hdr_alignment.py` reprojects unchanged *actual RGBE pixel data* into Godot's panorama convention. Source HDR sha256 `edac40a4a1579c695483a650bb6219f86aaaabff35ca3ec77b0f502557ebab75`; reprojected `4d191b286df3879dbe11c326c1ed9c1f56f4fce2179cfa13ede530cf4660e5c4`.
- In real Mobile image the corrected coordinate orientation DID alter specular/reflection face colors. It also exposed previously hidden artistic deficiency: **big flat light panels now reflect as entire silver/gray triangular faces**, rather than elegant localized polished-stone reflections.
- Tripling panorama intensity is materially WORSE: even more gray faces. Thus correct axes are technically vital but not aesthetic acceptance.

## Reproducible controlled real Mobile variants

Exact same D20 GLB, camera, imported original face/edge materials, background and render method for these Mobile variants. Relative ROI rectangular x=250..779 y=150..729; **background-inclusive diagnostic, not a score of physical fidelity or aesthetic quality**.

| Real source PNG | Studio experiment | Mean ROI luma (0..255) | P90 | ROI bright fraction >100 |
|---|---|---:|---:|---:|
| `blender_cycles.png` | Blender Cycles, source studio (renderer differs) | 66.27 | 144.00 | 18.08% |
| `godot_ibl.png` | Mobile old Sky/AGX uncorrected HDR U | 52.37 | 67.67 | 4.39% |
| `godot_aligned.png` | Mobile Sky/AGX, physically aligned HDR U | 67.01 | 102.67 | 14.29% |
| `godot_aligned_boost.png` | aligned + 3× radiance | 91.07 | 123.33 | 31.65% |
| `godot_narrow50.png` | narrower physical panels 50%, radiance 1× | **57.89** | **87.00** | **8.51%** |
| `godot_narrow30.png` | narrow studio panels 30% | 51.40 | 72.67 | 6.60% |
| `godot_narrow50_no_omni.png` | narrow50, all 3 OmniLight energy=0 | 51.50 | 85.33 | 8.34% |
| `godot_compatibility.png` | older Compatibility test, not directly comparable | 13.07 | 18.00 | 0.79% |

`tools/visual/d20_narrow_studio.py` generates actual radiance from **the same authored four physical studio-card parameters** as the Blender generator, changes only angular size. Reconstructed 100% cards match original Radiance RGBE with mean absolute byte difference `1.1967` from numerical quantization. Authored 50% HDR sha256 `e99d1af82328b6b0b622af965c8450216b61cc41dc44d983b97cf92575e73495`, 30% sha256 `6fa6365f2fcae33fc83a6fa4b96f60b3977f23bf3fae9654bd8fe73b7c1f1be3`. No shader hacks to paint highlights onto the GLB.

## Artistic critique and what to do next

- Narrow 50% looks **less washed and more volumetric** than the physically aligned full-size studio, 30% gets too dark. Preserve `narrow50` as a *controlled lookdev candidate*, **NOT approved game art**.
- Removing all three OmniLights in `narrow50_no_omni` barely changes the pale lateral facets. Thus the main silver facet wash is **Sky/IBL reflection on planar normal directions**, NOT Omni direct lighting. Do not keep blindly increasing/decreasing point lights to fix those panels.
- Major remaining differences versus Codex actual Cycles reference: fully planar gray facet reflections rather than shaped polished black highlights; texture/normal micro-curvature may need controlled tuning; gold inserts and physical 6/9 punctuation need refinement. Neutral AO R=255 is NOT a valid baked spatial AO; regenerate and check ray-derived AO before claiming AO PASS.
- Next bounded art experiment: study actual reflection directions of upper faces versus bevel normal field; author small focused specular sources that glint chiefly on physically cut bevels instead of whole numbered faces, WITHOUT returning the old glossy raised-looking rim. Alternative narrow controlled normal-field/roughness variation should be evidenced by genuine Blender+Mobile source PNG A/B, not painted screen pixels.
- After owner **art signoff**, review Jolt face value mapping, temporal 24fps actual rolls, then ARM64 Android AVD and on-device OnePlus Nord 3. No merging from the experiment before those gates.
- The previous high-cost pipeline ran every time any script was edited. `.github/workflows/d20-learn-codex.yml` now uses targeted `paths` so pure HDR A/B only triggers native Godot diagnostic, without re-sculpting a known exact-source GLB.

**Independent external vision critic:** NOT_VERIFIED. Technical script tests and numerical brightness cannot substitute for visually comparing the original frames with the user's Codex reference.
