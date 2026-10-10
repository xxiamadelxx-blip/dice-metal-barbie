# Visual acceptance contract · user-approved Concept 3 (minimalist)

**Authority:** Discovery Round D, explicitly approved by user. Visual concept image: third ("Минималистичный") of the three comparative concepts, not generic Android/Godot default controls. Actual client screenshot must be compared against it by a critic, not just checked for nonblack pixels.

## Hard visual requirements
1. **Dice are the heroes.** Readably large sculptural polyhedra; black obsidian with visible polished bevels, reflective cool graphite highlights, fine warm-gold engraving and clear face numerals. Flat featureless dark polygons FAIL.
2. **Stage is a physical surface.** Matte black-velvet tabletop with tactile texture, restrained rail accents; not flat grey rectangles. Full table kept in strictly 90-degree overhead orthographic camera; no cinematic tilting.
3. **Mobile control style matches Concept 3.** Bottom selector displays only working dice D4/D6/D8/D12/D20, no fake choices. Round blue roll action, concise result/copy, hidden complexity, no generic dropdown form. Controls do not obscure 3D space.
4. **Actual visible physical outcome.** Measured top face or D4 apex == copied result after actual Jolt sleep; under no condition may visual polish change mass/collider asymmetrically or choose result retrospectively.
5. **Animation.** Dice fly from above and toward the viewer, bounce, hit and settle inside table. D20 natural 1/20 aura/flash originates at actual die, not HUD (this remains M5 *not implemented*).
6. **Functional completeness** sound/haptics based on actual collision, state persistence and advanced mechanics via hidden controls belong to later M4/M5 gates and must not be marked done by visual QA.

## Evidence for every visual PR
- Native Mesa/Xvfb real Godot start / movement / settled screenshots at 720x1280, not generated mockups
- Side-by-side critique against approved Concept 3, with concrete defect list and accept/reject
- Physical rules / Jolt regression and Android ARM64 debug export
- Independent phone/emulator visual certification still NOT VERIFIED while Android emulator GPU fails
- Don't merge a cosmetic PR solely because it has green screenshots; examine the actual pixels.

## Known baseline failures
The original M3 screenshot showed featureless D6 (small black cube with white digit), table of plain black polygons, a Godot dropdown, rectangular text buttons and technical labels. Initial layout fix PR #21 addressed table/dock overlap only. This PR is still an iterative step toward, **not a claim of equivalence to**, Concept 3.

## Gauntlet continuation: reconstructed stage and sculpted polyhedra

- First iteration relied on large basic solids and hovering gold cylinders. It failed the reference.
- Current work on [PR #23](https://github.com/xxiamadelxx-blip/dice-metal-barbie/pull/23) uses true inward-chamfered shells on D4, D8, D12 and D20. Faces retain exact Jolt numbering normals; hairline bronze shapes sit inside the face rather than enclosing the die in a floating cage. D6 uses a small actual beveled mesh.
- Four frozen, non-colliding display dice introduce the product at startup. All are removed on the first roll. They **are not** presented as historical dice results and cannot influence the Jolt solver.
- Larger engraved face numerals, micro-normal-mapped velvet and procedural normal-based studio reflections. Existing simple minimal chip/blue throw control is preserved.
- [Verified renderer screenshots, four dice](https://github.com/xxiamadelxx-blip/dice-metal-barbie/actions/runs/38062634632) and [newer cloth/light screenshots](https://github.com/xxiamadelxx-blip/dice-metal-barbie/actions/runs/38063129218). The screenshots are actual Linux/Mesa Godot rendered frames, **NOT an Android device**.
- Detected that earlier visual workflow erroneously reported success despite GDScript parse errors. The workflow now **fails explicitly on** `SCRIPT ERROR`, `Parse Error`, `Compile Error`, `Invalid call` or failed script loads, as well as blank/unchanged frames. The geometry source was fixed and retested.
- Physics tests additionally check D4/D8/D12/D20 bevel/inlay triangle counts and require the decorative start models to be removed before any real throw.

**Artistic gate remains OPEN / NOT ACCEPTED:** model fidelity and premium reflective detail are still short of the approved high-quality concept image, even though the new stage is substantially closer than the original single-die testbed. Future iterations should prioritize truly engraved numeral meshes, high quality normal/roughness/albedo maps and proper 3D asset baking or Blender automation, before production approval. Do not merge simply because CI passes.
