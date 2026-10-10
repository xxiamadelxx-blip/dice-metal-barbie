# D&D 3D Dice 🎲

Offline physics-driven D&D dice for Android, initially targeted at **OnePlus Nord 3**.

## State of the project

- **M0 / Discovery:** approved 2026-10-10.
- **M1 / Architecture:** approved 2026-10-10: Godot 4.6 family, Jolt Physics, GDScript.
- **M2 / Foundation:** work in progress. The runnable Godot scene is a **physics sandbox**, **not** a validated dice roller, final UI, or signed release.
- **M3–M6:** unimplemented. In particular, a uniformly distributed roll must match the visible face.

## Run / test

Install **Godot 4.6.3 standard**. Open `project.godot`; press F6/F5 or run:

```sh
godot --headless --path . --editor --quit
godot --headless --path . --script res://tests/smoke.gd
godot --path .
```

The test scene creates an actual 3D table and a rigid-body D6 when you tap **Бросить D6**. This is deliberately labeled an M2 physics experiment. No number is advertised as a result yet.

GitHub Actions runs parser/import tests, deterministic mechanics tests and attempts an Android **debug** export. Debug builds are not stable production-signed releases. CI outcomes must be checked before claiming a successful APK.

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

**No backend, tracking, accounts, paid services or remote AI inference.**
