# M5 — Independent D20 learning from Codex instruction (real Blender/Godot evidence)

**Date:** 2026-10-12. **Scope:** isolated independent experimental D20; not the user's Codex GLB and NOT app art acceptance.
**Verified art-source SHA:** `da42b5bd1fed13ce0883613dca438200261971e5`; [exact-source successful cloud execution #38273994084](https://github.com/xxiamadelxx-blip/dice-metal-barbie/actions/runs/38273994084); artifact: `LEARNED-CODEX-D20-real-source-Blender-Godot`.
**Input lesson:** owner-supplied `D20_instruction.md` from Codex, specifically Boolean Exact engraving, independent gold meshes, die bevels, round-trip glTF, 1024 PBR slots, Cycles and studio lighting.
**No generated images were used.**

## Actual deliverables

- `tools/blender/learn_codex_d20.py` independently builds a new icosahedral D20, explicit numbers 1–20/opposite pairs 21, 4-segment beveled stone, per-face actual Boolean engraving, 20 separate gold mesh inserts and 5x4 UV0.
- `build/learned-d20/learned_d20.glb` (from Actions artifact) SHA256 `85dbd1d2662d6d226470b54c98c3a2ac5b52ae84f052f6767ce93f64a39e5951`, 3,736,936 bytes.
- Real `authored.blend` and **deleted-authoring-mesh then reimported-GLB** `roundtrip_import.blend`; `blender_cycles.png` is rendered FROM that reimport.
- Independently recorded `godot_compatibility.png` and `godot_mobile.png`; latter is Godot 4.6.3 Mobile Vulkan **desktop Mesa**, not Android.
- Real shared Blender/Godot Radiance RGBE `learned_studio.hdr`, valid RLE scanlines after fixing Blender's accidental PNG payload with .hdr extension.
- Composite original unretouched Blender/Compatibility PNGs and SHA manifest; native Godot screenshots not retouched, RGB hashes archived in `render_manifest.json`.

## Engineering lesson that changed the result

The first exported GLB contained glTF texture slots but **incorrect image pixel values**. Visual tests were initially GREEN although:
- Embedded albedo Base Color was mean approximately **(3,4,4) byte values**, far darker than Codex's ~23/25/28.
- Packed ORM was constant **R=0, G=255, B=0**. AO red zero **blackened all ambient**, and roughness green 255 produced a completely matte surface.
- An AO bake reported `made` from Blender internal image state even though actual saved `cycles_true_ao.png` was entirely black. Do not count this as legitimate spatial AO.

Solution:
1. Write dark sRGB source albedo near (23,25,28), not near-zero raw bytes.
2. Validate and deterministically repair packed glTF ORM image BYTES after Blender exporter: R=255 neutral AO, Green sourced from actual authored roughness map, B=0 dielectric. This is a transparent **fallback**, not an asserted AO bake. Source is reimported into Blender after this repair.
3. Inspect real final GLB pixel values from PNG embedded bufferView. Actual exported mean Base Color `(23.012,25.049,28.115)`; ORM `(255,43.58,0)`, G =~0.171.
4. Verify exact same glTF GLB on Godot Compatibility and Mobile, authored coating restored in the isolated Godot review scene. Do not mistake glTF extension presence for successful import of coating.
5. Codex's explicit fixes for headless OpenImageDenoise, active UV atlas and actual engine PNG capture have been applied. Other real failures in our independent script: reading a deleted Blender object during receipt, examining glTF mesh names rather than object node names, using `--editor --quit` without `--import`, and a mislabeled PNG pretending to be HDR.

## Current art FAIL versus Codex

The finished studio D20 is still **below the Codex reference**. Even after channel repair, the independently built die has less convincing facet reflections and numeral bevel details. Godot Compatibility is darker than the corresponding Cycles source; mobile Mesa is more legible, but the environment/material correspondence is not yet studio-calibrated. Camera/model pose differs from the owner-provided Codex image, so do not derive a similarity percentage from pixel crops.

Remaining:
- [ ] Genuine non-black **spatial** AO or verified geometry AO on engraved face islands; current R=1 intentionally neutral.
- [ ] Correct label 6/9 physical punctuation and improve per-face glyph placement/metal lip detailing; 20 gold mesh inserts, 21 total meshes, not 23 Codex objects.
- [ ] Calibrate specular HDR probe orientation/intensity across Blender Cycles and Godot **Mobile**, preserve dielectric IOR and roughness.
- [ ] Compare original unretouched source PNGs under deliberately matched camera, object scale and controlled light, independent art critique.
- [ ] Validate Jolt face-to-number mapping, actual 24fps throws and Android app after art acceptance; no OnePlus Nord 3 physical data.
- [ ] Repair misleading `cycles_ao: made` runtime manifest until the saved spatial AO is verified.

## What NOT to do

- Do not replace this experiment by copying Codex's ready-made GLB; that would defeat the user's learning test.
- Do not merge this candidate or overwrite PR #23/main. It is not artist-approved.
- Do not run Android/Jolt smoke after every environment slider; keep cheap local art lookdev first, then broad regression once visual acceptance is reached.
- Do not call a white fallback map a real AO bake. Keep all on-device status NOT_VERIFIED.
