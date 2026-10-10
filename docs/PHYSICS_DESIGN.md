# Physics design

Godot 4.6.3 / Jolt at proposed 120 Hz physics tick (benchmark on phone). RigidBody3D per die with convex hull and appropriate collision properties, steady contact/sleep detection and hard timeout. Table should have a physically plausible visible boundary, not invisible collision magic. PhysicsLayer reserved for table/dice/future interactive trays/towers; cosmetics cannot affect physical shape silently.

D6 M2 test: one real rigid cube on a collidable box table with solid rails, no face numbers or final result. Material currently approximate and untested. M3: replace with properly numbered bodies/face normals, contact-driven audio, camera-space readability, D4 and D100 specialized rigs.

**Non-negotiable:** any final displayed value must match the actual visible label on a fully stopped die. Until tested, do not show a number in M2 sandbox.

