# M5: real native Godot render of exact recovered owner-selected BlenderKit PBR on repaired one 500k D20

2026-10-14 | creative-3d | Art accepted: **NO** | Native engine import: **PASS** | UV/native Blender rebake: **OPEN** | Physical OnePlus Nord 3: **NOT TESTED**

## What actually ran (local PRIVATE environment)

The 2026-10-13 owner-selected BlenderKit **Procedural Obsidian** original node `.blend` SHA256 `3ff237798e8b2498070f886ca43071e43156034358b3694cd7f6c90a63a77cae` was restored from existing ChatGPT user Library archives. Never repeat that it was never downloaded: the original source is available privately.

The repaired actual 500000-triangle GLB with exact archived 2026-10-13 baked black albedo, normal and roughness texture bytes transplanted onto stone-only materials was preserved privately at `/Дайс/D20_500K_REAL_RECOVERED_ORIGINAL_OBSIDIAN_PRIVATE_MASTER.zip`. New private test GLB SHA256 `b9f87c663c23b47473261ee11732acd2fa099e37089efeb9e881c532193b5d68`.

A **redistributable open-source Godot 4.6.3 stable native engine binary** (no private data) was built from existing actual GitHub Actions container [run #38627152931](https://github.com/xxiamadelxx-blip/dice-metal-barbie/actions/runs/38627152931) with artifact `M5-Godot-4-6-3-local-private-material-render-toolkit`. The engine was extracted to the isolated local user project, permitting private material render with no third-party licensed input uploaded to public CI.

Actual local project imports:
- `d20_selected.glb` = selected authentic PBR repaired 500k D20, source SHA above.
- `studio.hdr` = original author-approved HDR (restored from Library).
- `tools/visual/m5_private_selected_obsidian_capture.gd` = source-owned version of the **executed native** Godot screenshot script; no private binaries committed.

Native editor `--headless --editor --import --quit` **PASS**, no texture or GLB import errors. Full Godot stage under Xvfb:`--display-driver x11 --rendering-method gl_compatibility --audio-driver Dummy --script ...` **PASS**. Runtime engine: `4.6.3.stable.official.7d41c59c4`, actual renderer **gl_compatibility**, actual GPU **Mesa llvmpipe LLVM 19.1.7 256 bits**; viewport `1000×850`, 4x MSAA. **DO NOT MISREPRESENT AS MOBILE VULKAN OR NORD 3 FPS.**

### Engine proof

Godot native source logs: `PRIVATE_REAL_GODOT_IMPORTED_500K mesh_instances=21 triangles=500000`, 20 gold MeshInstance3D objects, 2 stone materials, all source PBR loaded. `PRIVATE_REAL_GODOT_HDR_LOADED true`. PNG `save_png err=0`. After real HDR visual revision the original HDR environment still drives the IBL, while a matte 3D plane outside D20 silhouette hides visible white environment cards.

Ran **four independent actual Godot renders** with original material and exactly same GLB:

| HDR Yaw | Real PNG persisted privately |
|---:|---|
| 0° | `/Дайс/D20_500K_GODOT_SELECTED_HDR_YAW000.png` |
| 35° | `/Дайс/D20_500K_GODOT_SELECTED_HDR_YAW035.png` |
| 70° | `/Дайс/D20_500K_GODOT_SELECTED_HDR_YAW070.png` |
| 110° | `/Дайс/D20_500K_GODOT_SELECTED_HDR_YAW110.png` |

All source pixels remain accessible from the **user's private ChatGPT Library**; consolidated zoomable original 2×2 sheet: `/Дайс/D20_500K_REAL_GODOT_RECOVERED_BLENDKIT_4_HDR_COMPARE.png`. **No private licensed BlenderKit source, texture bytes or material-bearing GLB are committed into the public repository.**

### New real blocker: confirmed UV and unacceptable look

An actual trimesh inspection of exported GLB stone primitives found:
- Stone face material: **51,104 indexed triangles**, UV values within `u≈0.032–0.968`, `v≈0.076–0.973`; chart projection not from original 20146-triangle source.
- Stone satin chamfer material: **168,896 indexed triangles**, UV values span **u=-0.5…4.0, v=-2…2**, so using source 1024 px tangent-space normal on these surfaces repeats out of authored chart space. The original PBR is **genuine**, but the original tangent normal map was baked for a *different mesh UV atlas*.
- Original selected source GLB had 20,146 triangles, and stone UV within ~[0.02,0.98]; the unchanged source texture data cannot be accurately sampled on 500k GLB without **native Blender rebake / verified UV transfer**.
- Native Godot visually shows dull near-black facets with poorly legible darker gold at oblique angles, wrong/noisy specular on some cuts and insufficient width of reflections. All 4 HDR yaw variants fail premium artistic acceptance. **No post-hoc image brightening is passed off as a shader fix**.

### Exact next pass

Blender 4 native genuine source bake in private environment with recovered `selected-source.blend`; new unique 500k UV unwrap, original procedural node bump/roughness network and correct tangent normal, use the same gold (20 distinct glyphs) and same die geometry and physics hull. Verify index count remains exactly 500000 and normal content has nonflat pixel range and seamless face boundaries. Render in private Blender and local Godot, actual 16/20 crops, then in-game Jolt/Android FPS; retain private material in Library, never place licensed source into public GitHub. Existing native Blender runtime export [workflow m5-private-local-blender-runtime-toolkit](../../.github/workflows/m5-private-local-blender-runtime-toolkit.yml) was launched; the current model's native new UV bake **NOT YET VERIFIED**. Container-backed operations temporarily failed after attempting to retrieve the large engine toolkit, so no claim of successful re-bake.

Maintain M5 **OPEN**, independent Qwen visual critique **NOT VERIFIED**, `main` and PR #23 untouched.
