# M5 restoration of selected original BlenderKit obsidian from private user Library

Date: 2026-10-14. Branch: `experiment/m5-learn-codex-d20`. This document records **ACTUAL RECOVERY**. Do not repeat false claims that the selected source was never downloaded or cannot be recovered because an anonymous API returns HTTP403.

## Original chosen source, recovered and SHA-verified

- BlenderKit **Procedural Obsidian**, author **diaverx miky**, asset UUID `92e31cbc-5b4e-4ead-a966-84bf106808c3`, free RoyaltyFree as recorded by the source provenance.
- On **2026-10-13**, private working files were saved in the ChatGPT **personal Library**, folder `/Дайс/`. The raw original `selected-source.blend` is inside:
  - `/Дайс/selected-polished-obsidian-d20-proof.zip` (archive member `selected-source.blend`)
  - `/obsidian-model-and-proof.zip` (member `original-control/selected-source.blend`)
  - `/obsidian-gold-visibility-proof.zip` (member `inputs/selected-source.blend`).
- Source `.blend` SHA256 **`3ff237798e8b2498070f886ca43071e43156034358b3694cd7f6c90a63a77cae`**, verified byte for byte across all **three** separately persisted Library archives. Source size **4,215,232 bytes**. Original proof selected-baked D20 GLB SHA256 **`4c04c1707e1ed0d59f5bee286525059d85cdec5668c2ce5969d968d3a18221df`**.
- Genuine selected source baked **three PBR PNG maps** at 1024px (original filenames `normal`, `albedo`, `roughness`), extracted from the verified selected GLB, not generated. Selected material original base color PNG is purely black and has a fine normal; reflectivity comes from physically correct dielectric specular/lighting, not painted reflections.
- A fourth user-private **recovery bundle** including exact source node blend, original HDR, repaired master GLB and original rendering proof has now been uploaded to the **personal Library** at:
  `/Дайс/D20_500K_REAL_RECOVERED_ORIGINAL_OBSIDIAN_PRIVATE_MASTER.zip`
  with ZIP SHA256 **`821071e47a6474cef33333127f699b36cdb8743fdf7ab83337251c89ed07bae2`**.
  This is the canonical recovery point for future agent handoffs; **do not fetch via anonymous BlenderKit endpoint first**, retrieve this private archive from Library.

## Actual private proof of original material applied to repaired 500k D20

- Existing repaired source master **500,000 true glTF indexed triangles** (`220,000` black engraved stone + `280,000` gold, **20 separate actual glyph meshes**): SHA256 `67650874fe979f6b7b82ad0e596fd5ea8d3397c58c50fa0d5cf8e4c83c9edadf`.
- Authenticated original selected material's **exact PNG byte payloads** copied verbatim into the corrected master GLB (no image generation, no replacement material). Main stone facet glTF PBR properties migrated from original archived file with correct new texture indices. Facet chamfers use same source black color and normal but deliberate constant satin roughness `0.22`. **All 500,000 triangle positions/UVs/nodes/indices and the gold material are unchanged**, verified. Final new GLB SHA256 **`b9f87c663c23b47473261ee11732acd2fa099e37089efeb9e881c532193b5d68`**, **18,534,760 bytes**.
- A **real VTK 9.6.2 OpenGL renderer** with the saved original studio HDR and unchanged camera/lighting rendered both old self-authored gray placeholder and recovered original-obsidian replacement on the **identical new 500k geometry** for side-by-side review. Its before/after PNG and the new GLB are stored **ONLY in the private user Library ZIP** above and in the conversation's attached files. **Not** Godot screenshots; do not claim the final 500k selected source was rendered in Godot or passed Android FPS.
- **Important geometry-UV caveat**: The original selected D20 normal map was baked on the former 20,146-triangle original source UV layout; new 500k D20 still has a different 5×4 chart UV layout. The original selected fine normal texture is embedded unaltered, but an original native Blender Cycles tangent-space re-bake **onto the 500k D20 UVs** is still required for exact mapping and M5 art acceptance.
- Do not commit original licensed node blend, standalone baked image maps, or this **private bundle** to the PUBLIC GitHub repository. Consult BlenderKit RoyaltyFree redistribution limitations before shipping PBR in an APK. **The private preview GLB is for the user's testing**, not automatic public asset redistributing.

## Engineering failure and next actions

The original material was **not lost**. Prior agents confused a new experiment branch / public CI artifact availability with the personal Library archives, repeatedly regenerated unrelated self-authored black/gray PBR placeholders, then misreported the selected source as blocked. This was a state-recovery failure, not a material availability limitation.

Next visual pass: use the **recovered private original `.blend`** and new **fixed 500k GLB** from Library, perform correct UV-native Cycles tangent bake, compare real Blender and Godot screenshots; preserve 20 numbered gold engravings, no purple, Jolt collider/face mapping unchanged. Real physical Android OnePlus Nord3 and independent vision review NOT VERIFIED. Main and Draft PR #23 unchanged.
