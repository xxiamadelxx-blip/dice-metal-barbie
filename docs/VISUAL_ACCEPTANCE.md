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
