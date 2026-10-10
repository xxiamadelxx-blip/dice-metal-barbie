# M3 physical dice · continuous 24fps frame-by-frame visual checklist

**Authority:** approved M0/M1 design, `docs/DESIGN.md`, `docs/VISUAL_ACCEPTANCE.md`, `docs/GAUNTLET_LOOP.md`.
**Status:** eight-mode pipeline authored, **NOT VERIFIED until exact-head CI completes and original videos/sheets are inspected**.
No "AI screenshot" / generated frame is admissible as evidence. Target OnePlus Nord 3 is NOT VERIFIED.

## Record these 8 REAL Jolt throws separately
| Capture key | Real bodies | Top-face and numeric source | Primary frame critique |
| --- | --- | --- | --- |
| D4 | 1 physical tetrahedron | Upper vertex + 3 adjacent numbered facets | No imaginary top-face label |
| D6 | 1 physical cube | Upper face | Rail/rim collisions, ambiguous edge recovery |
| D8 | 1 physical octahedron | Upper face | Axis rotation and face orientation |
| D12 | 1 physical dodecahedron | Upper face | Number-legibility and bevel continuity |
| D20 | 1 physical icosahedron | Upper face | D20-only die-origin aura for natural 1/20 |
| D10 | 1 physical 10-face trapezohedron | Printed 0 = rolled 10, actual upper kite face | Symmetry, 0 label attached to 3D die |
| D100 | **1 real 100-face** trapezohedron | Upper face of 102-vertex Jolt convex hull | 100 unique real planes, stop stability, readable HUD |
| D100_PAIR | **2 independent physical** D10 bodies | Combine actually upper 0..9 digits; 00+0=100 | Both bodies move and settle, no inherited previous result |

## Per-second 24-screen setlist (mandatory)
For each source movie, the independent reviewer or transparent self-critic must inspect the exhaustive `ALL-24-frames-D<key>-second-XX.jpg` ordered sheets. Per **EVERY decoded 720x1280 image**, retain `every-frame-D<key>.jsonl` with timestamp, changed pixels, duplicate streak, black fraction. Retain the **uncut** original FFmpeg screen recording and exact Jolt READY / GO / DONE / SAVED handshake, signed log of physical outcome and seconds to settle.

1. Opening frames: correct playable Godot table, existing die UI and no system overlays/blank renderer.
2. Actual throw launch: die appears from authorised top trajectory, not suddenly replaced by a result.
3. Mid-flight: visible pose/position changes, physically plausible motion, no game-plane clipping or camera tilt.
4. Impact/settling: real rim/table contact, bounded edge-rest recovery, no frozen 1-second active interval.
5. Rest pose: unique face/vertex above world, compare rendered label with actual `ShapeMath.top_value` (D10/D100) or approved D4 apex mapping.
6. HUD/result: equals the physical Jolt callback; `D100_PAIR` requires separate tens/ones, no recycled prior D12/D20 clip.
7. Exit/tail: 1 second after result without black frames; recorder closes before Godot switches/terminates.
8. Each 24-frame sheet must exist in order. Neither duplicated captured frames nor `fps=24` proves 24 unique GPU render frames/s. Report measured duplicates, native Godot frames/sec separately.

## Blocking checks
- Any missing model, error parsing GDScript, Jolt timeout, invalid face, unfair substitution, stuck die or result mismatch: **FAIL**.
- Any frame blank during active capture, wrong body in a labelled movie, still shot masquerading as motion, or missing consecutive contact sheet: **FAIL**.
- All old 5 face-physics and temporal regressions plus new D10/D100/PAIR must remain GREEN on same source SHA.
- Physical Android AVD gets independent capture and confirmation, and hand-held Nord 3 FPS remains NOT VERIFIED until tested. **M5 premium visual style not accepted by functional M3 CI.**

## Real emulator visual incident and fix
Run [#38090191673](https://github.com/xxiamadelxx-blip/dice-metal-barbie/actions/runs/38090191673) produced repeated uniform white tutorial frames (mean ~226.6) because the scripted tap at 593,388 was **above** the Android immersive tutorial button. The source `launch-after-immersive-dismiss.png` shows actual game dice below the overlaid panel; `Got it` occupies x533..673 and y399..496 at 720x1280. The corrected bounded test detects the pale overlay on its original screenshot and taps (605,447), then saves `launch-after-system-consent.png`. This is a **diagnostic fix proposal** until reverified in real AVD; don't describe this as successful new Android test prematurely.
