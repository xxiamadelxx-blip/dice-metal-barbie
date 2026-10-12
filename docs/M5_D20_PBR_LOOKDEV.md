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
