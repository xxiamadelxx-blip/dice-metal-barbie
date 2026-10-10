# M3 D4: correct top-apex numeral convention

A true regular tetrahedral D4 cannot rest with a horizontal **top face**. It settles on one bottom triangle with one apex up. The visible result must therefore be read at the **top vertex**. The design prints that apex's number three times, on the three adjoining sloping faces near the vertex. Thus the same result is physically visible from the owner-approved fixed overhead camera without fabricating an impossible upper surface.

- Collision shape is the exact symmetric four-vertex tetrahedron.
- Visual mesh has four outward-facing triangles.
- Each top-apex number (1..4) is repeated on three neighbouring faces: 12 glyphs, no labels affect mass or collisions.
- Before launch secure Crypto picks one of 12 orientation-preserving tetrahedron symmetries. All four labels have three equivalent choices for each generic final physical pose. No end-of-roll rotation correction.
- Jolt decides the final top apex after true rigid-body sleep; a genuine ambiguity returns no result, with up to three label-independent physical recovery nudges.
- Integrated with existing D6/D8/D12/D20 chooser. Preliminary physics integration includes 12 live throws.
- This is a short smoke test, **not** statistical fairness evidence. Real Android glyph readability, long-run fairness, dynamic audio/haptic and other shapes remain unverified.

Tests: `godot --headless --path . --script res://tests/d4_geometry.gd` and `godot --headless --path . --script res://tests/numbered_d4_physics.gd`.
