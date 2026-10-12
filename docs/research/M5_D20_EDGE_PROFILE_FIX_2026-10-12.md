# M5 independent D20: flattened facet-to-edge junction (2026-10-12)

**Real source:** `5941b1096a48a50b731d167d230a04deab03c382`, independent generated D20 from `tools/blender/learn_codex_d20.py`. Codex's ready-made GLB is **not** used. This is an isolated M5 art experiment: PR #23 and `main` are unchanged.

**Verification:** [real original Blender/Cycles + Godot Compatibility and Mobile Mesa run #38278837373](https://github.com/xxiamadelxx-blip/dice-metal-barbie/actions/runs/38278837373), artifact `LEARNED-CODEX-D20-real-source-Blender-Godot` (ID `11760546884`). GLB SHA256 `ad8b2b9b239b16367a3655c11e6cafca8fffd07363fc5f8883db24b7a7ff1fdd`.

## Owner's newly identified defect
The broad mirrored rim around every triangular face reads visually as **raised edges surrounding a sunken front panel**. This was primarily an edge BRDF/profile artifact, not outward polygonal displacement. For the previous GLB, the source top plane was ~0.794652 and Gold_20 top ~0.764802, a physical engraving recess of ~0.02985 units. No original rim geometry was higher than the top face.

## Actual controlled correction
| Property | Before | After |
| --- | --- | --- |
| Die edge bevel width | 0.023 | **0.010** |
| Bevel segments | 4 | **3** |
| Bevel material | same glossy stone | **dedicated dielectric satin edge** |
| Edge roughness | shared face roughness G ~0.17 | **constant 0.31** |
| Edge clearcoat weight/roughness | same .20/.09 as face | **.05 / .30** |
| Triangular facet PBR | dark obsidian, true normal, albedo G roughness | **unchanged** |
| Physical glyph grooves | 20 individual Boolean/recessed gold glyphs | **unchanged** |
| Hull outside face halfspaces | earlier visually ambiguous | **measured max +4.47e-8 (PASS <.0002)** |

The edge material is assigned on actual Blender `BEVEL` polygons and imported as its own glTF `PolishedObsidian_EdgeSatin` surface, not a baked painted outline. Godot's art-only import adapter preserves its `.31/.05/.30` values rather than applying primary facet clearcoat to all surfaces. Boolean mesh halfspace test verifies **no outward raised lip**, irrespective of shader highlight.

A side discovery required correcting Blender glTF texture serialization: copying the stone material had generated black embedded BaseColor PNG bytes. Source RGB PNG remained correct. `enforce_exported_pbr_channels()` now repacks original authored BaseColor bytes for both surfaces and validated ORM G. Independently inspected final GLB: original BaseColor RGB mean `(23.01,25.05,28.12)`, ORM RGB mean `(255,43.58,0)`; bevel factor `0.31`, clearcoat `0.05`, coat roughness `0.30`. AO remains **neutral white fallback, NOT a valid spatial AO bake**.

## Art critic
- **PASS, narrow edge bug:** visual comparison of exact-size original Blender and Godot frames shows the broad metallic-looking raised ribbon is much narrower; triangular face planes read more continuous. Engine screenshots and source logs in artifact.
- **PASS, technical:** exact-source Blender regenerated assets; GLS/Godot Compatibility native image + Godot Mobile Mesa original frame, GLB byte contracts and numeric halfspace assertion all passed.
- **NOT AN ART ACCEPTANCE:** black obsidian highlights still less nuanced than Codex; some gold glyphs have overly deep shadowing, actual spatial AO remains unproven; 6/9 readability, full physics Jolt roll, true Android and owner approval remain open.
- Rendering path: Godot **Mobile on Mesa desktop**, not OnePlus Nord 3 device. No claims of mobile hardware FPS.

## Next bounded pass
1. Preserve this narrower edge treatment as independent experimental candidate; do not reintroduce a glossy edge rim.
2. Improve **polished facet reflections** and numeral inlay edge details while holding the above halfspace and channel gates; compare same camera/source GLB actual PNGs.
3. Once the owner likes the actual art, validate genuine geometry AO, d20 face mapping during Jolt rolls, all 24fps real frames, Android AVD and physical handset. Do not merge to main or PR #23 before approvals.
