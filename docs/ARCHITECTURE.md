# Architecture — approved M1 / M2 baseline

## Stack
Godot **4.6.3** standard, **Jolt Physics** 3D, GDScript, Godot Mobile renderer. LibGDX + Bullet is a contingency only if an evidence-based blocker emerges. Android preset uses a stable application ID `org.dicemetalbarbie.dnddice`. Android release signing is deferred to M6.

## Runtime layers
1. App flow / input lock / screens.
2. Pure game rules and validated formula grammar.
3. Secure roll source: `Crypto.generate_random_bytes` + rejection sampling; injectable fake entropy **tests only**.
4. Catalog: geometry, numbering, local face normal and orientation, collision hull for each shape.
5. Jolt rigid-body scene: physically solid table + walls, later towers/trays.
6. Outcome reconciliation: geometry/face identification based on local normals transformed to world; NO hidden final snaps or fake results.
7. Physical contact-driven audio/haptic; 3D origin-dependent critical VFX for D20.
8. Persist versioned configuration, named presets, history, statistics, choices.

### Hard research risk
Approach A: physical final orientation determines face, then check each face distribution statistically. Approach B: secure RNG determines face first and a physical launch must realize that face without perceptible reorientation. Consider geometry-preserving symmetry mappings to decouple face labels from physical landing bias, but prove/verify them per die. For D4, upper-value reading differs from ordinary flat-top dice. Single D100's geometry and stop times are risky. D100 two percentile D10 are not a hidden substitute for single-D100 option.

### M2 isolation
`src/main.gd` is a real D6 rigid-body sandbox, not a finished gameplay flow. It intentionally shows NO rolled number. `src/core/dice_rng.gd` has rejection-sampling RNG code not wired into physics sandbox; `src/core/dice_rules.gd` has first pure rules. M3 must establish end-to-end physical correctness before connecting UI results. No completed features should be inferred from test coverage of pure math.

### Android
Headless engine/editor validation, pure tests, Android ARM64 debug export in GitHub Actions. Stable signing and update-over-install smoke test after selecting protected release secrets. Never commit a keystore. CI artifacts are temporary and debug-key signed; release uploads are separate.


## Offline creative toolchain separation (M5 development only)
See [toolchain architecture](TOOLCHAIN_ARCHITECTURE.md) and [routing matrix](CREATIVE_TOOLCHAIN.md). Blender/Material Maker/2D art tools/MeshLab run **only at build time**, never inside the Android app. They produce static licensed assets with manifests and provenance. Source of truth for physical face outcome and collisions remains Godot/Jolt. Optional design integrations operate outside the Android runtime, can be bypassed with offline tools and require current user authorization. All model/art decisions are checked by autonomous Gauntlet Loop and recorded as evidence. `main` must remain untouched until acceptance.
