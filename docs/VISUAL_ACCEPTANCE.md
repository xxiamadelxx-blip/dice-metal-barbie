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

## M5 next Gauntlet: D20/D6 physical pocket + TextMesh experiment (PR #23)

Implementation checkpoint on 2026-10-10:
- New `src/visual/engraved_gem.gd` builds all D20/D6 display faces from the same numeric vertex layout as their existing Jolt hulls, with narrow polygonal bevel shoulders and actual cavities (open polygonal inset, vertical walls and lowered floors).
- A separate `TextMesh` for each numeral provides 3D extruded metallic glyphs positioned *inside* the recessed face pocket. Old `Label3D` nodes remain in the scene tree but are invisible, preserving mapping/test metadata.
- This **is not a full boolean engraving of each glyph contour into the stone**. It is a procedural pocket + recessed 3D inlay. The eventual production asset will still need a real font-contour relief/normal bake or Blender-produced glTF before artistic acceptance.
- No new geometry participates in physics: existing mass, exact collision resources, 1..N number mapping and settled-face verification are unchanged. No added external font binary or online art dependency; the Godot fallback vector font is used.
- `tests/engraved_assets.gd` tests one visible geometric asset per face, recessed floors/walls, actual extruded text, and physics invariance. Native renderer QA now executes this test before capturing images.
- Treat this iteration as **functional/visual R&D**, not automatic acceptance. Confirm native rendered images manually and test the physical Android GPU and readability/FPS on Nord 3. PR remains DRAFT, `main` untouched.

## Native macro critique and material correction (Pass 4)
- Actual Godot [macro capture](https://github.com/xxiamadelxx-blip/dice-metal-barbie/actions/runs/38065091959), `native-06-d20-detail.png`, was reviewed, NOT accepted: the large dark pockets made D20 look like a hollow wireframe cage despite correct mesh/test counters. Full-screen D6 had the same issue.
- Corrective sculpt: narrower bevel shoulder; substantially more continuous stone surface per face; shallow inset, with obsidian-shaded **stone floors** (same mineral shader as outer face) instead of pitch-black pocket cut-outs; metallic digits physically touch the pocket floor.
- Added machine-checkable anti-cage constraints (pocket depth, face coverage and stone-floor shader). These do not replace a human artistic review of the next native PNGs.

## M5 branch-only GLB scene integration (2026-10-10)
- [Blender output from CI](https://github.com/xxiamadelxx-blip/dice-metal-barbie/actions/runs/38069118714) is pinned into `src/assets/generated/d20_boolean_engraved.glb` and `d6_boolean_engraved.glb` by the trusted same-repo draft PR workflow. Commit `f6c1150`, no main mutation. The workflow will not rewrite assets on subsequent runs when both binaries exist.
- Runtime `Premium.decorate_die` now loads these actual Blender-imported PackedScene visuals when available, disables redundant procedural mesh/legacy labels while keeping the original collision, mass, true physics result and test metadata. Missing assets fall back to prior procedural visuals.
- The native visual CI must capture the running Godot GLB frame, not simply the standalone Blender render. The visual acceptance gate stays OPEN until inspecting that evidence and handset GPU FPS.

## M5 runtime material Gauntlet checkpoint
- Imported GLB shader treatment is authored in `Premium._finish_glb_node()`: dark obsidian mineral shader on stone faces and warm PBR bronze on genuine 3D inlays, to match the other polyhedra under Godot Mobile and native Mesa. These are VISUAL material overrides only.
- Godot native screenshot audit of the raw imported GLB [run #38069316833](https://github.com/xxiamadelxx-blip/dice-metal-barbie/actions/runs/38069316833) was technically PASS but artistically incomplete: imported D20 and D6 were flat-blue/grey instead of black obsidian. The follow-up material pass corrects this without changing physically determined results.
- [Integrated-GLB Android ARM64 export and Jolt regression #38069316836](https://github.com/xxiamadelxx-blip/dice-metal-barbie/actions/runs/38069316836) PASS on prior material colors. Further screenshots and Android export are required for this new material tweak before final approval.

## M5 die-origin critical pulse Gauntlet
A 3D, world-horizontal, emission-lit pair of expanding torus waves is now triggered *only* by the `roll_completed` result of a genuine physical D20 if its result is natural 1 (crimson) or 20 (gold). The transient pulse attaches to the real die, never to a HUD overlay, spawns no colliders and does not alter mass or the face mapping. `tests/critical_aura.gd` verifies non-D20, noncritical outcomes, idempotence, die origin, cleanup and Jolt invariants. Real native/GPU screenshots and handset FPS must still be reviewed; headless structural pass alone is not an artistic pass.

### Autonomous QA iteration on critical aura
A strict `mass == 1.1` test falsely rejected the unchanged physics body due to floating-point representation. The check now uses `is_equal_approx`; the physical collision-shape identity check remains exact. To prevent falsely claiming art without pixels, real Godot/Mesa QA now additionally captures the **explicitly staged** aura appearance in `native-07-staged-gold-pulse.png` and `native-08-staged-crimson-pulse.png`, requiring differences from no-aura and one another. These staged frames are evidence of effect visibility only, **not** evidence of physically rolling a natural 1/20.

### Aura visual Gauntlet: first full-render preview rejected
[Actual native critical-effect screenshots, run #38071811062](https://github.com/xxiamadelxx-blip/dice-metal-barbie/actions/runs/38071811062) showed thick oversized toroidal rings intruding on the macro dock. Despite green structural tests, this failed artistic critique. This corrective pass reduces outer radius, narrows ring thickness, halves alpha and softens OmniLight. New autonomous pixel critic evaluates both actual staged pulse screenshots and fails if strong warm pulse-colored pixels appear in the safety strip just above the control dock. A staged aura frame only certifies rendered appearance, not an actually rolled critical result.

## M5 four-die authored art: D8 / D12 real Godot screenshot gate
[Blender + MeshLab CI #38076794535](https://github.com/xxiamadelxx-blip/dice-metal-barbie/actions/runs/38076794535) **PASS**: authored GLB, true inset digit geometry, UV/PBR for D20 D6 D8 D12, and actual MeshLab PLY import → OBJ re-export of all four carved shells. The PLY swap was a Gauntlet correction for the old MeshLab OBJ-importer assertion; Blender JSON GLB face numbering independently verified. **Native visual QA now captures two additional MACRO screenshots** after actual D8 and D12 physical scene throws and explicitly fails if their authored GLB did not load. These frame captures check the runtime appearance, not only Blender previews. Refuse M5 signoff if text legibility or style remains poor even when CI passes. The real OnePlus Nord 3 remains an unverified device gate.

### All five authored dice / near-flush bronze Gauntlet
[Blender + MeshLab run #38077474794](https://github.com/xxiamadelxx-blip/dice-metal-barbie/actions/runs/38077474794) **PASS** for five authored GLBs including D4 12-imprint apex reading. Visual inspection of standalone D4 Cycles preview **REJECTED**: numerals almost invisible due excessive inset depth. Subsequent correction lifts inset mesh from 0.016 to 0.0035 units beneath stone surface (physical Boolean-cut pocket remains); warm inlay emission is modestly increased. New real Godot/Mesa `native-11-d4-apex-detail.png` capture uses an actual Jolt throw and asserts the Blender scene is attached. This is not art signoff until that screenshot is inspected; older D4 was legible only via 2D label overlay, now prohibited by approved premium asset direction.

## Five-model production-art checkpoint · 2026-10-10
D4 glyph-depth Gauntlet: first real D4 Cycles preview failed visibility; stone model regenerated with bronze inlay lifted from 0.016 to **0.0035** local units below original surface, no floating label overlay. [Five-model Blender/MeshLab #38077736895](https://github.com/xxiamadelxx-blip/dice-metal-barbie/actions/runs/38077736895) generated 12 apex-specific D4 imprints, 4 other carved models and re-exported all 5 QA-only PLY meshes via MeshLab. [Native rendered suite #38078034043](https://github.com/xxiamadelxx-blip/dice-metal-barbie/actions/runs/38078034043) confirmed **90 runtime asset contract checks, 0 failure**, real physical D4/D8/D12 macro screenshot and rest result; the D4 source vertex-to-face mapping is untouched. [Full physical regression + ARM64 #38078033946](https://github.com/xxiamadelxx-blip/dice-metal-barbie/actions/runs/38078033946) passed. Still NOT artistic reference approved: graphite faceting and off-axis gold engraving are muted, and Android handset GPU/FPS/user upgrade untested. Keep issue #24 and PR #23 open/draft. 

Gauntlet pipeline correction: Blender 4.x binary glTF can differ after regeneration even with stable geometric source, causing pointless bot commits. The build workflow now first reads **actual HEAD changed paths** and skips expensive Blender/MeshLab job on unrelated source edits; it only writes GLBs when `tools/blender/generate_die_assets.py` changed in the head commit, plus actual byte comparison. This avoids re-pinning binaries after every CI/report documentation change.
