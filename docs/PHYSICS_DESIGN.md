# Physics design

Godot 4.6.3 / Jolt at proposed 120 Hz physics tick (benchmark on phone). RigidBody3D per die with convex hull and appropriate collision properties, steady contact/sleep detection and hard timeout. Table should have a physically plausible visible boundary, not invisible collision magic. PhysicsLayer reserved for table/dice/future interactive trays/towers; cosmetics cannot affect physical shape silently.

D6 M2 test: one real rigid cube on a collidable box table with solid rails, no face numbers or final result. Material currently approximate and untested. M3: replace with properly numbered bodies/face normals, contact-driven audio, camera-space readability, D4 and D100 specialized rigs.

**Non-negotiable:** any final displayed value must match the actual visible label on a fully stopped die. Until tested, do not show a number in M2 sandbox.


## D10 / D100 shape contract (M3, 2026-10-11)
`src/core/trapezohedron.gd` generates the geometric dual of a regular n-gonal antiprism (n=5 for D10, n=50 for D100). The dual has 2n planar four-corner kite faces, 2n+2 convex vertices and balanced rotational/mirror symmetry. Faces are indexed consistently and physically numbered 1..2n. The single D100 uses a **genuine** 102-point convex Jolt collision hull; any practical face-size, draw-call, wobble and numerals limitations remain M3/M5 QA targets, not silent substitution with an arbitrary random outcome. A separate D100 percentile mode uses two D10 Jolt bodies; the printed face 10 is interpreted as digit zero only for percentile arithmetic. UI reveals the two alternative D100 modes explicitly.

The digital value must be inferred only after `RigidBody3D.sleeping` from the highest transformed actual face normal, with explicit ambiguity rejection and bounded non-outcome-specific recovery impulses. No animated face snap or post-hoc random value. D100's angular neighbor separation is much smaller than D10's, so its numerical ambiguity tolerance is scale-adjusted; this requires real physics validation and high-volume reliability tests. New shape material/labels are temporary mechanically useful previews, **not** M5 artistic acceptance.
