# D&D 3D Dice 🎲

## Unified Engineering Router · mandatory agent entry

The **single canonical engineering architecture** routes development across code, Godot/Jolt, 3D, materials, UI, **audio/haptics**, architecture/C4/ADR, security, performance, Android release, supply chain and agent recovery.

Every new Dice agent and every **«продолжай» / «завис» / handoff** must start with [AGENTS.md](AGENTS.md) → [ENGINEERING_ROUTER.md](docs/ENGINEERING_ROUTER.md) → [engineering routes registry](config/engineering_routes.json) and [durable handoff](docs/handoff/ACTIVE_ROUTING_HANDOFF.json). An authorized terminal runs:

```sh
python3 scripts/engineering_router.py enter --intent "продолжай"
python3 scripts/engineering_router.py enter --intent "завис"
python3 scripts/engineering_router.py handoff
python3 scripts/engineering_router.py audit
python3 scripts/engineering_router.py validate
```

The default independent critic uses **local Ollama in GitHub Actions** without an API key (see [Gauntlet Autopilot](docs/GAUNTLET_AUTOPILOT.md)). The router checks local git state, chooses a relevant evidence path, provides alternatives and never pretends an uninstalled tool or reviewer ran. To persist progress for another agent, create an evidence-backed `checkpoint`, **commit and push** the handoff JSON. Actual scope-specific tests and independent critique are performed through the pre-existing [Gauntlet Loop](docs/GAUNTLET_LOOP.md), not faked by the routing CLI. This infrastructure does not install every creative/security program and is not itself product feature completion.

Offline Dungeons & Dragons 3D dice for Android (initial target OnePlus Nord 3). Godot 4.6.3 / Jolt Physics / GDScript.

## Current stage · 2026-10-10

- **M0 and M1:** user-approved requirements, minimalist overhead concept and Godot/Jolt architecture.
- **M2:** automated foundation PASS, phone hardware QA NOT VERIFIED.
- **M3:** PARTIAL PASS / IN PROGRESS. Five real, numbered 3D polyhedra **D4, D6, D8, D12, D20**, convex Jolt colliders, dice stay inside velvet table, actual face-derived result (top apex for D4) after physical sleep, no artificial end-of-roll face snap.
- **M4–M6:** full rules/history/presets, polished UI/audio/haptics/VFX, production signing and release QA NOT completed.

Choose one of **D4 / D6 / D8 / D12 / D20**, throw, watch the body bounce and settle on the fixed overhead table, see/copy its numeric result. Natural 1/20 D20 critical **text** exists, aura/flash not yet implemented. This is a developer physics testbed, not the approved final UI.

### Real evidence

[CI #38054012551](https://github.com/xxiamadelxx-blip/dice-metal-barbie/actions/runs/38054012551) / [PR #17](https://github.com/xxiamadelxx-blip/dice-metal-barbie/pull/17)
- Secure-roll mathematics: 14 tests pass
- D6 149 symmetry checks, **12/12** real Jolt throws / 135 checks
- D8 269 symmetry/geometry checks, **12/12** real Jolt throws / 167 checks
- D12 1542 geometry/symmetry checks, **10/10** real Jolt throws / 151 checks
- D20 1026 geometry checks, **8/8** real Jolt throws / 143 checks
- D4 142 tetrahedral geometry checks, **12/12** genuine Jolt throws / 175 checks; apex number printed three times on visible sloping faces
- Android ARM64 **debug APK** export PASS, versionCode 6 / `0.0.6-m3-d4`.

The Gauntlet cycles exposed D6/D8/D20 edge-rest cases, which were repaired with bounded world-space *physical* nudges. An ambiguous face is **not** treated as a valid result. Tests still cover too few throws to establish statistically powered fairness.

**NOT VERIFIED:** Nord 3 installation, actual label rendering/legibility and FPS, independently audited visual quality, physics fairness under large-N trials, final UI, realistic audio/haptics, D10/D100, mixed dice, production release signing. See [M3 Issues #12](https://github.com/xxiamadelxx-blip/dice-metal-barbie/issues/12) and [#13](https://github.com/xxiamadelxx-blip/dice-metal-barbie/issues/13).

## Test commands

Use Godot 4.6.3 standard locally or GitHub Actions cloud; no physical PC is necessary.

```sh
godot --headless --path . --editor --quit
godot --headless --path . --script res://tests/smoke.gd
godot --headless --path . --script res://tests/physics_smoke.gd
godot --headless --path . --script res://tests/cube_symmetry.gd
godot --headless --path . --script res://tests/numbered_d6_physics.gd
godot --headless --path . --script res://tests/d8_geometry.gd
godot --headless --path . --script res://tests/numbered_d8_physics.gd
godot --headless --path . --script res://tests/d12_geometry.gd
godot --headless --path . --script res://tests/numbered_d12_physics.gd
godot --headless --path . --script res://tests/d20_geometry.gd
godot --headless --path . --script res://tests/numbered_d20_physics.gd
godot --headless --path . --script res://tests/d4_geometry.gd
godot --headless --path . --script res://tests/numbered_d4_physics.gd
```

## Android

Package: `org.dicemetalbarbie.dnddice`; M3 debug versionCode **6**, versionName `0.0.6-m3-d4`. Debug certificate is stable across v3–v6 CI test artifacts, **not** a production key. Real upgrade-over-install and data-preservation are NOT VERIFIED. See [RELEASE.md](docs/RELEASE.md).

## Canonical documents

[PRD](docs/PRD.md) · [ARCHITECTURE](docs/ARCHITECTURE.md) · [CONTEXT](docs/CONTEXT.md) · [DESIGN](docs/DESIGN.md) · [MILESTONES](docs/MILESTONES.md) · [ROADMAP](docs/ROADMAP.md) · [GAUNTLET_LOOP](docs/GAUNTLET_LOOP.md) · [TEST_PLAN](docs/TEST_PLAN.md) · [PHYSICS_DESIGN](docs/PHYSICS_DESIGN.md) · [D12 research](docs/research/M3_NUMBERED_D12.md) · [D4 research](docs/research/M3_NUMBERED_D4.md).
