# D&D 3D Dice 🎲

Offline Android physics-driven D&D dice for OnePlus Nord 3. Uses **Godot 4.6.3 / Jolt Physics / GDScript**.

## Current state (2026-10-10)

| Phase | Status |
|---|---|
| M0 Discovery | User approved |
| M1 Architecture | User approved |
| M2 Foundation | Automated PASS; device still NOT VERIFIED |
| M3 Polyhedra | **IN PROGRESS**: real numbered Jolt D6 and D20 integrated and passing short physical trials |
| M4 Mechanics | NOT complete: full formulas, groups, history and presets missing |
| M5 Polish | NOT started: final UI, realistic sound, haptics and critical VFX missing |
| M6 Release | NOT started: stable production signing and device release QA |

**Latest automated evidence:** [CI #38046017124](https://github.com/xxiamadelxx-blip/dice-metal-barbie/actions/runs/38046017124) · [PR #10](https://github.com/xxiamadelxx-blip/dice-metal-barbie/pull/10): 14/14 mechanics, D6 symmetry 149/149, D6 numbered physics 12/12 (123 checks), D20 geometry 1026/1026, D20 numbered physics 8/8 (135 checks), Android ARM64 debug export. **These tiny samples do not statistically prove physical fairness.**

The app currently contains a **technical M3 tabletop testbed**, not final UI. Select **D6 / D20**, press Throw, let a numbered 3D body collide with a black velvet table and settle, read the actual top-face result, then optionally copy it. Text-only natural 1/20 D20 critical status. The top-down camera is fixed.

No network/backend/account/payment service. No release signature yet. Fonts, graphics and actual Android handset behavior are **NOT VERIFIED** by tests run in a headless cloud CI environment. Real physical D4/D8/D10/D12/D100 have not been built yet.

## Run and test

Install Godot 4.6.3 (standard) or use GitHub Actions; a local PC is not required for cloud CI.

```sh
godot --headless --path . --editor --quit
godot --headless --path . --script res://tests/smoke.gd
godot --headless --path . --script res://tests/physics_smoke.gd
godot --headless --path . --script res://tests/cube_symmetry.gd
godot --headless --path . --script res://tests/numbered_d6_physics.gd
godot --headless --path . --script res://tests/d20_geometry.gd
godot --headless --path . --script res://tests/numbered_d20_physics.gd
```

## Android test artifact

Debug APK from [CI #38046017124](https://github.com/xxiamadelxx-blip/dice-metal-barbie/actions/runs/38046017124): `org.dicemetalbarbie.dnddice`, versionCode **3**, versionName `0.0.3-m3-d20`. The signer matches previous **debug** packages; upgrade on the user's handset is still NOT VERIFIED. Production signing and release upgrade testing belong to M6 (see [docs/RELEASE.md](docs/RELEASE.md)).

## Project documentation

[PRD](docs/PRD.md) · [Architecture](docs/ARCHITECTURE.md) · [Design](docs/DESIGN.md) · [Roadmap](docs/ROADMAP.md) · [Milestones](docs/MILESTONES.md) · [Test plan](docs/TEST_PLAN.md) · [Gauntlet Loop](docs/GAUNTLET_LOOP.md) · [Physics design](docs/PHYSICS_DESIGN.md) · [M3 D6](docs/research/M3_NUMBERED_D6.md) · [M3 D20](docs/research/M3_NUMBERED_D20.md)

We only claim PASS when actual command/test/artifact evidence exists. Independent UI/device critic remains NOT VERIFIED.
