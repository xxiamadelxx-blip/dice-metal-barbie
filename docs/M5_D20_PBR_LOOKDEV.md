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
