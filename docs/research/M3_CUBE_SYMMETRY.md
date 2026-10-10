# M3 research spike: unbiased D6 by pre-roll cubic symmetry

Status: **UNVERIFIED until CI and physical demo**. Scope limited to an ideal cube, **not** D4/D8/D10/D12/D20/D100 and **not** a completed dice roller.

## Idea
The group of proper geometric rotations of a cube has exactly 24 elements. For any given physically settled cube orientation, there are exactly four rotations which position each of its six painted face labels at the top. Therefore, if an independent cryptographically secure source samples one of these 24 rotations uniformly **before** release, and the physical shape, collision hull, inertia tensor and world-frame forces are invariant under these rotations, then each observed labeled face is exactly uniform 1/6 *conditional on the physical trajectory*. The die is never snapped after impact and the labels remain rigidly attached throughout.

This differs from choosing an arbitrary face after observing the outcome, which would be dishonest. The secured random selection happens **before the launch**; the subsequent true rigid-body physics determines the top face.

The prototype enumerates all rotations from mutually perpendicular coordinate directions x and y, with z = x×y (determinant +1), and assigns conventional opposite faces: 1↔6, 2↔5, 3↔4. The test exhaustively validates 24 unique rotations, determinant +1, and an exact 4:4:4:4:4:4 multiplicity of outcomes across several arbitrary settled body orientations.

## Essential caveats
- Numeral meshes/textures must be attached to the same rotating rigid body **before** the throw. Collision geometry cannot depend on the selected label transform.
- A perfectly symmetric collision shape is required. Raised glyph geometry in the collision hull, asymmetrical mass or contact dependence on labels invalidates the proof.
- Launch impulse must be in world coordinates and independent of the symmetry choice. Any local-axis-dependent impulses can introduce a bias.
- Numerical integration/rounding can introduce tiny symmetry-dependent differences; statistical and full physical tests are still needed. The proof is a mathematical design rationale, not a measurement of Godot/Jolt fairness.
- D4's visible number convention, D10's numeric faces and physical D100's 100-face shape each need separate symmetry/orientation and legibility work; do not generalize blindly.
- The selected RNG picks a random orientation; **it does not predetermine an arbitrary target result**. The final face is still a physically obtained result.

## Test
`godot --headless --path . --script res://tests/cube_symmetry.gd`

The test is deliberately independent of any GUI. Next development step: attach physically readable D6 face markings to the 3D rigid body, initialize orientation with a sampled proper rotation, compute final face after sleep, verify labels vs stored results and run many headless Jolt trajectories. Do not claim M3 PASS before that entire loop.
