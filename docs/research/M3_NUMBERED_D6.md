# M3 · Numbered D6 physics Gauntlet

## Scope
Live Jolt physics testbed with a **numbered** physical D6. Six Label3D numerals are attached to the six local geometric faces, without changing the symmetric collision box or mass. An unbiased 1..24 secure sample selects one proper symmetry **before** the world-space impulse and fall. The number reported after natural sleep is read from the actual uppermost oriented face normal. No after-roll snap, scene swap, preselected number or simulated output animation.

## Checks
- `tests/cube_symmetry.gd`: exhaustive cube group proof (149 checks, previous baseline).
- `tests/physics_smoke.gd`: overhead and enclosed physics.
- `tests/numbered_d6_physics.gd`: 6 labels and face-normal consistency, 12 consecutive true physics trials, sleep/stopping, timeout, table limits, exact UI-result-versus-facing-face agreement. Counts displayed for observation only, **12 trials do not prove statistical uniformity**.
- Android arm64 debug export after tests.

## What remains unknown
Screenshot/video or phone rendering: NOT VERIFIED. Label3D glyph facing/legibility requires a captured frame and a device assessment. Long-run Jolt physical fairness must be measured with a larger independent statistical suite including multiple launch conditions. Geometry for D4/D8/D10/D12/D20/D100 and their physics/faces is not implemented. Sound, haptics, skins and final UX are not included. Do not mark milestone M3 complete based on this PR alone.
