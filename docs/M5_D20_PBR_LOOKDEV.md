# M5 D20 real Blender PBR lookdev vertical slice

User directive 2026-10-12: apply actual artist + AI-assisted texture production rather than tuning flat procedural shader colors indefinitely. Alpha4 is UX-only reference; premium art must exceed it.

## Implemented source candidate
- **One type first: physical D20**, not a surprise rewrite of all Jolt dice or D4 apex.
- Original D20 exact number-placement source `model(20)`, Boolean cut geometry and separate recessed bronze unchanged.
- Final cut-render shell gets `D20FaceAtlas`: **5x4 separate planar face UV tiles**, one for each numbered source face; 10% tile padding (including cut geometry). Old spherical seams no longer run across the glyphs of D20.
- Embedded D20 1024² albedo, roughness and tangent-space normal PBR via Blender texture pipeline, while D4/6/8/12 original 256² maps remain unchanged until verified.
- **Genuine Blender Cycles AO bake** from actual D20 Boolean-cut 3D shell into 1024² `d20_cycles_baked_ao.png` with 10-pixel bake margin; verifies meaningful cavity occlusion, manifest and ImageMagick dimensions. Not a noise-based artificial AO.
- **Important limit:** this first AO PNG is a PRODUCTION LOOKDEV ARTIFACT, not yet a glTF texture channel imported by Godot. Manifest explicitly marks `runtime_ao=NOT_IN_GLTF_YET_IMPORT_TEST_REQUIRED`. Likewise this is not yet a high-poly→low-poly normal bake, real photographed velvet, or an AI-created surface.
- Original GLB export embeds D20 1024² base/normal/roughness for direct real Godot result, with previous Godot PBR material compatibility override retained until evidence supports safely replacing it. No model collider, mass, label mapping or offline logic changed.
- New fail-closed Blender/manifest validator checks real 5×4 layout marker, AO cavity values, actual 1024² PNG IHDR, 5 GLBs and geometry map invariants; same-run Gaia pipeline still tests Godot/Jolt/AArch64/Android and the Qwen critic.

## Acceptance gates
1. Blender batch job must actually bake AO and output `D20_CYCLES_AO_BAKED` with meaningful physical cavity samples; check PNG + images inside GLB.
2. Read original Cycles and actual Godot 720×1280 and D20 macro frames, compare before/after. Need balanced dark obsidian and readable numbering, not flat clay.
3. If above real tests pass, next is separate AO source glTF import test with `glTF Material Output` or explicit supported Godot occlusion material and a **true high→low** bake; then physically scanned or AI image-to-material black velvet and lacquered ebony, licensing proofs.
4. Full independent human aesthetic review still OPEN, no claimed AI generator until genuinely used. OnePlus Nord3 hardware still OPEN.

## Cycles bake first-run false-green found from raw PNG (2026-10-12)

The real Blender #38183549384 D20 AO PNG was **ALL BLACK** on every 1,048,576 pixel, though Cycles claimed the bake finished and the earlier validator counted all black pixels as 'cavities'. This is a true content failure. New bake initializes a fully white image with no bake clear, then requires **both dark and bright areas**, significant image standard deviation and fewer than 65% pixels dark. The source remains RED if true AO is not generated. This changes only the visual lookdev tool, not the app physics. No 'AI created PBR art' claims.

## Pixel-proven UV0 correction; new local AO production experiment

Exact [Gauntlet #38186006813](https://github.com/xxiamadelxx-blip/dice-metal-barbie/actions/runs/38186006813) confirmed all 20 numbered atlas cells on physical D20 GLB primary `TEXCOORD_0`, all PBR slots reading UV0: **PASS**. Its true image `d20_cycles_baked_ao.png` was still effectively a black-face silhouette with ~68.4% pure white, ~31.35% pure black and **only 0.236% midtone samples**, so the new independent spatial AO checker correctly failed. Not approved and no runtime AO.

New source swaps stock `bpy.ops.object.bake(type='AO')` for a *real* Cycles `ShaderNodeAmbientOcclusion` hemisphere measurement (`only_local=True`, distance 0.115 world units, 24 ray samples) connected temporarily to emission, then baked via Cycles `EMIT`. This isolates actual engraving cavity geometry from unrestricted scene shadows and **restores the original authored PBR material links** before GLB export. Does NOT artificially paint black lines. Exact new Cycles bake PNG, histogram and real Godot screenshot remain pending until the next Gauntlet succeeds.

## M5 recovery: geometry AO via Blender BVHTree, not mislabeled Cycles

The original Blender 4.0.2 headless stock Cycles AO, local AO via emission and white control proved output INVALID; separate EXTERNAL mode was also confirmed unsuccessful. These are explicit failures, not successful quality gates. Next source iteration calculates **real per-texel physical occlusion by Blender BVHTree ray intersections on the exact Boolean-cut D20**, sampling 512×512 UV0 with 20 deterministic cosine-weighted local hemisphere rays and bilinear output to 1024². Metadata calls it **Blender BVHTree geometry AO**; it is not Cycles, a neural material or a painted placeholder. The existing spatial midtone and geometric normal/number 20-face export validation remain mandatory, and output is still not connected to runtime Godot until compatible PBR import verification. New generation and full Android Gauntlet not yet verified.

## Real Blender BVH AO first geometric sample

[Gauntlet #38212524817](https://github.com/xxiamadelxx-blip/dice-metal-barbie/actions/runs/38212524817) successfully processed original Boolean-cut D20 UV0 with **55,899 512px source texels, 1,117,980 actual hemisphere rays and 13,440 real geometry intersections**. This is the first genuine Blender geometry AO signal, with AO luminance std 0.03617, but only **0.509% grayscale midtones** versus the unchanged strict gate 0.8%, so downstream QA correctly remains RED. Increased physical sampling from 20 to 36 directions and local radius from 0.17 to 0.24 units, not the test threshold. Actual next PNG remains unverified, project `main` unchanged.

## Exact-source geometric AO resolution and honest integration boundary (2026-10-12)

At [unified #38213538757](https://github.com/xxiamadelxx-blip/dice-metal-barbie/actions/runs/38213538757), source `51612370a980e1355d897e84cdcd4503930f79c7`, original Blender logs show `D20_GEOMETRY_AO_BAKED: rays=2012364 hit_fraction=0.01199 midtones=0.01054`, with the standalone real spatial AO checker **PASS** (previous failure was 0.00509 vs required >0.008). This is **Blender BVHTree real mesh-based occlusion**, not a successful Cycles bake. No `occlusionTexture` import to live Godot material has yet been shown; no AO-derived screen improvement can be claimed. At the same source the native D4 facet smoke critic is **FAIL** (`6.63` against `8`), the Android source-reroll selector drawer is **FAIL**, and the code-only separate Qwen 7B critic ran but cannot approve texture appearance. See [M5 action audit](research/M5_FREE_PREMIUM_MATERIALS_ACTIONABLE_AUDIT_2026-10-12.md). Do not lower thresholds or alter approved Jolt face contracts.

## Verified original Codex GLB and real Godot proof recovered (2026-10-12)

**Stop prioritizing the unrelated procedural D20 generator for premium art.** The user-provided Codex reference is an ACTUAL `d20_obsidian_gold.glb`, preserved in the user's private Library and included in privately delivered `D20_Art_Assets.zip`. Exact original file SHA256 `c5d971370fae51328461cbd220293d9445a14d7fd6f182b623f52551dbb8fa27`, 2,672,464 bytes, 23 source meshes, 20 glyphs plus 6/9 dots, true `TEXCOORD_0`, albedo/normal/ORM/AO maps, `KHR_materials_clearcoat`. Source obsidian `metallicFactor=0`, clearcoat `0.12`, clearcoat roughness `0.13`, imported AO active, no stone emission. These are observed original GLB properties, NOT shader guesses.

**Real completed specialist branch already exists** at [`feat/m5-d20-reference-godot-proof`](https://github.com/xxiamadelxx-blip/dice-metal-barbie/tree/feat/m5-d20-reference-godot-proof), including:
- [Source-grounded proof and actual screenshots](https://github.com/xxiamadelxx-blip/dice-metal-barbie/blob/feat/m5-d20-reference-godot-proof/docs/research/D20_REFERENCE_GODOT_PROOF_2026-10-12.md).
- [Original true Godot Mobile render](https://github.com/xxiamadelxx-blip/dice-metal-barbie/blob/feat/m5-d20-reference-godot-proof/docs/evidence/d20-reference-2026-10-12/godot-mobile-original-oblique.png), [Blender inlay-refined candidate Mobile](https://github.com/xxiamadelxx-blip/dice-metal-barbie/blob/feat/m5-d20-reference-godot-proof/docs/evidence/d20-reference-2026-10-12/godot-mobile-candidate-oblique.png) and [approved orthographic camera candidate view](https://github.com/xxiamadelxx-blip/dice-metal-barbie/blob/feat/m5-d20-reference-godot-proof/docs/evidence/d20-reference-2026-10-12/godot-mobile-candidate-overhead.png).
- [Reproducible standalone Godot review](https://github.com/xxiamadelxx-blip/dice-metal-barbie/tree/feat/m5-d20-reference-godot-proof/tools/visual/d20_reference_review) with import-material clearcoat adapter and geometry visibility checks.

**Local verification (same Library binary files, NOT from screenshot):** `D20_Art_Assets.zip` contains candidate `d20_inlay_refined.glb` SHA256 `80bd2337d1f0fdee1e02a039b81693a46e0633d54eb2b5621c8afe90595739a2`. Both stone meshes have 9,544 triangles and EXACT SAME 4,774 unique vertex positions at five decimal places, despite Blender re-export changing split-vertex counts 11,570→13,012. Representative inlays `Gold_01`, `Gold_02`, `Gold_03`, `Gold_08`, `Gold_20` translate by norm `0.023` model units. No statement that all raw buffer bytes/topology ordering are identical; source geometric invariant is the stronger supported claim.

**Critical failure of our alternative:** [real experimental cloud run #38239424270](https://github.com/xxiamadelxx-blip/dice-metal-barbie/actions/runs/38239424270) generated Blender and Godot screenshots from the repository's DIFFERENT procedural D20. Sky/ReflectionProbe A/B passed as actual engine execution, but images remain dark, lifeless and visibly below the owner-provided Codex reference. It is not the same source model; **do not claim parity or promote this lookdev**. Its earlier #38238918298 run even falsely went green with `Node not inside tree` and a light panel directly visible; corrected screenshot, error and emitter checks in `d8bb33c`.

**Next actual integration route:** Take the original/candidate authored GLB from the user's authorized private artifact source, preserve die geometry and local face directions, add an explicit material import adapter that retains `KHR_materials_clearcoat`/AO/normal/color space, verify face-to-Jolt mapping and result visibility; then true static overhead screenshots, actual physical 24fps throws and Android Mobile hardware gate. Existing game wrapper `Premium._finish_glb_node` only matches `Sculpted_Obsidian` / `Recessed_Bronze`, NOT this asset's `D20_engraved_obsidian` / `Gold_XX`, so do not apply its hard-coded metallic/coat/emission tuning blindly.

**Privacy/licensing gate:** Library original is a private user-provided GLB and is **not** in public GitHub. Do not silently publish it to a public repository or pretend a CI runner can access private Library bytes; use an approved transfer path or owner approval first. Do not rewrite M4/Jolt/physics or merge PR #23. Independent premium art and real Nord 3 acceptance remain NOT_VERIFIED.
