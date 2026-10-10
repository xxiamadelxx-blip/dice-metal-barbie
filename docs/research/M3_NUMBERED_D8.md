# M3 D8 · geometry, real physics and top face

Scope: a real eight-sided regular octahedron with six physical vertices, eight triangular, numbered faces and a Jolt ConvexPolygonShape3D body. Faces in opposite pairs add to 9. Exactly 24 proper octahedral rotations provide three symmetries per face, sampled securely **before** launch. The only result is derived from the upper numeral after the body sleeps. No post-roll correction.

Tests:
- `tests/d8_geometry.gd`: shape, winding, unique 1..8 labels, antipodal numbering, 24 shape symmetries, exhaustive 3-per-face multiplicity
- `tests/numbered_d8_physics.gd`: actual Jolt D8 collider, 8 attached glyphs, 12 real throws, sleep/result match, table boundaries and UI state
- Existing D6 and D20 suites, Android ARM64 debug export

**Scope limit:** small samples do not establish statistical fairness; actual Android visual glyph legibility and FPS remain NOT VERIFIED, as do independent critic and physical results for D4/D10/D12/D100. M3 remains partial.
