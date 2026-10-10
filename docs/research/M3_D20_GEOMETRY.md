# M3 · D20 regular icosahedron mathematical foundation

**Scope:** pure geometry, number mapping and pre-roll symmetries, NOT an interactive D20 body.

- 12 normalized golden-ratio vertices, 20 outward-wound triangular faces.
- 60 proper, not mirrored, shape-preserving spatial rotations, derived by mapping a reference triangle frame to each destination face in its three cyclic orientations.
- Unique D20 1..20 numbers assigned in 10 opposite pairs summing to 21; this is a generated (noncommercial) labeling layout.
- For an arbitrary generic final physical orientation, every D20 face number appears exactly **three** times under 60 uniformly sampled *pre-roll* proper symmetries.
- Ambiguous edge/vertex-up orientations yield `-1`; do not invent a result.
- CSPRNG must choose a uniform rotation index 1..60, and collision hull/inertia/launch must remain symmetric. Decorative numerals never affect the physical mass/collider.

**Automated gate:** `godot --headless --path . --script res://tests/d20_geometry.gd`

**Still pending:** actual ConvexPolygonShape3D runtime, face-aligned Label3D numbers, Jolt sleeping, natural 1/20 critical effect tests, Android rendering and statistical physical trials. This PR must not be counted as the complete D20 feature.
