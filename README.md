# D&D 3D Dice 🎲

Offline physics-driven D&D dice for Android, initially targeted at **OnePlus Nord 3**.

## State of the project

- **M0 / Discovery:** approved 2026-10-10.
- **M1 / Architecture:** approved 2026-10-10: Godot 4.6 family, Jolt Physics, GDScript.
- **M2 / Foundation:** automated gates **PASS** on 2026-10-10 ([PR #1](https://github.com/xxiamadelxx-blip/dice-metal-barbie/pull/1), [CI evidence](https://github.com/xxiamadelxx-blip/dice-metal-barbie/actions/runs/38043718230)). The runnable Godot scene is a **physics sandbox**, **not** a validated dice roller, final UI, or production-signed release. On-device launch remains **NOT VERIFIED** ([Issue #5](https://github.com/xxiamadelxx-blip/dice-metal-barbie/issues/5)).
- **M3 / 3D Dice:** underway. The first research spike ([PR #6](https://github.com/xxiamadelxx-blip/dice-metal-barbie/pull/6)) passed **149 exhaustive mathematical checks** of 24 proper cube symmetries, but **no real numbered die / physics fairness / visible face invariant** has been verified yet. M4–M6 remain unimplemented.

## Run / test

Install **Godot 4.6.3 standard**. Open `project.godot`; press F6/F5 or run:

```sh
godot --headless --path . --editor --quit
godot --headless --path . --script res://tests/smoke.gd
godot --headless --path . --script res://tests/physics_smoke.gd
godot --headless --path . --script res://tests/cube_symmetry.gd
godot --path .
```

The test scene creates an actual 3D table and a rigid-body D6 when you tap **Бросить D6**. This is deliberately labeled an M2 physics experiment. No number is advertised as a result yet.

GitHub Actions **passed** project import, 14 mechanics tests, physical Jolt smoke and the M3 cubic symmetry test; it also produced an Android **debug** APK, verified as an archive and using a debug signature. [Successful run](https://github.com/xxiamadelxx-blip/dice-metal-barbie/actions/runs/38044176479). Debug builds are NOT production-signed releases.

## Android export

`export_presets.cfg` contains the preliminary Android preset for `org.dicemetalbarbie.dnddice`. For local Android exports install matching Godot export templates, Android SDK and debug keystore. **Do not install an M2 debug APK over any future release signed by a different key.**

A stable release keystore is **not committed**. Android release signing and reproducible upgrade testing are M6 gates (see `docs/RELEASE.md`).

## Documentation

- [Product requirements](docs/PRD.md)
- [Architecture and risks](docs/ARCHITECTURE.md)
- [Design direction](docs/DESIGN.md)
- [Roadmap and gates](docs/MILESTONES.md)
- [Gauntlet Loop](docs/GAUNTLET_LOOP.md)
- [Tests and evidence](docs/TEST_PLAN.md)
- [Decisions](docs/decisions/0001-godot-jolt.md)
- [M3 cubic symmetry research](docs/research/M3_CUBE_SYMMETRY.md)

**No backend, tracking, accounts, paid services or remote AI inference.**
