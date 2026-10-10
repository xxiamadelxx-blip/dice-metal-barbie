# D&D 3D Dice 🎲

Offline Dungeons & Dragons 3D dice for Android (initial target OnePlus Nord 3). Godot 4.6.3 / Jolt Physics / GDScript.

## Current stage · 2026-10-10

- **M0 and M1:** user-approved requirements, minimalist overhead concept and Godot/Jolt architecture.
- **M2:** automated foundation PASS, phone hardware QA NOT VERIFIED.
- **M3:** PARTIAL PASS / IN PROGRESS. Five real, numbered 3D polyhedra **D4, D6, D8, D12, D20**, convex Jolt colliders, dice stay inside velvet table, actual face-derived result (top apex for D4) after physical sleep, no artificial end-of-roll face snap.
- **M4–M6:** full rules/history/presets, polished UI/audio/haptics/VFX, production signing and release QA NOT completed.

Choose one of **D4 / D6 / D8 / D12 / D20**, throw, watch the body bounce and settle on the fixed overhead table, see/copy its numeric result. Draft PR #23 now includes an experimental die-origin 3D natural-1/natural-20 D20 pulse, verified in Godot native cloud captures; production visual/phone acceptance remains OPEN. This is a developer physics testbed, not the approved final UI.

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

## Creative production toolchain and automatic routing
**Canonical agent policy:** [AGENTS.md](AGENTS.md) and [creative tool routing](docs/CREATIVE_TOOLCHAIN.md). [Tool installation audit](docs/TOOL_INSTALL_AUDIT.md) records what is really available, while [architecture diagram](docs/TOOLCHAIN_ARCHITECTURE.md) shows the dependency and acceptance gates. [Cloud installation probe](.github/workflows/creative-toolchain-probe.yml) tests Material Maker, MeshLab, Krita and GIMP on disposable Ubuntu GitHub Actions runners and publishes evidence.

**Task-specific choices:** Blender sculpts and exports visual GLBs; OpenSCAD handles dimensional prototypes; Inkscape supplies SVG ornaments; Material Maker or Python generates PBR maps; Krita/GIMP retouch art; ImageMagick/Pillow pack/test textures; MeshLab/Trimesh check mesh complexity; Godot is the sole runtime for Jolt physics/UI/VFX and exports Android; FFmpeg analyzes actual clips; Figma/Canva/Adobe Express/to3D are optional authorized external workflows, not release dependencies.

**Never silently treat an integration as authorized or an install probe as production-ready.** No paid API or external account is required. A green cloud job never replaces real Nord 3 performance/art review. All development remains in draft PR #23, not `main`.

**Install audit snapshot (2026-10-10):** all four optional Linux editors were installed on Ubuntu 24.04 in [run #38075529457](https://github.com/xxiamadelxx-blip/dice-metal-barbie/actions/runs/38075529457). GIMP and Material Maker passed bounded CLI commands; Krita and MeshLab require Xvfb; their version/help commands now PASS under Xvfb in [run #38075709599](https://github.com/xxiamadelxx-blip/dice-metal-barbie/actions/runs/38075709599). Installation is not a claim of production-capable automation. See [detailed audit](docs/TOOL_INSTALL_AUDIT.md).

## M5 authored-asset test checkpoint (2026-10-10)
Five independently numbered, collision-decoupled GLB dice are now on draft PR #23: **D4 apex-reading with 12 physical engravings, D6, D8, D12 and D20**, using the same Blender PBR maps and real Bronze inset geometry. [Five-model Blender/MeshLab #38077736895](https://github.com/xxiamadelxx-blip/dice-metal-barbie/actions/runs/38077736895) passed; [native Godot/Mesa visual #38078034043](https://github.com/xxiamadelxx-blip/dice-metal-barbie/actions/runs/38078034043) passed with **90 sculpted-asset checks, 0 fails**, real physical macro frames for D4/D8/D12 and genuine D20/D6 throws. [ARM64 APK and Jolt #38078033946](https://github.com/xxiamadelxx-blip/dice-metal-barbie/actions/runs/38078033946) passed all CI tests and debug export. This is **not final artistic or Nord 3 handset acceptance**; device install/FPS and signed upgrade remain NOT VERIFIED. Script-specific Blender CI gate prevents unrelated PR docs/QA edits from rewriting GLB assets or restarting an expensive sculpt step.
