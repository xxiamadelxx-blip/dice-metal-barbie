# Milestones and verifiable gates

| Milestone | Status | Evidence / remaining blockers |
|---|---|---|
| M0 Discovery | APPROVED | Interview / agreed product |
| M1 Architecture | APPROVED | Godot 4.6 and Jolt selection |
| M2 Foundation | AUTOMATED PASS; DEVICE NOT VERIFIED | [PR #1](https://github.com/xxiamadelxx-blip/dice-metal-barbie/pull/1) / [Issue #5](https://github.com/xxiamadelxx-blip/dice-metal-barbie/issues/5) |
| M3 Physical dice | **PARTIAL PASS / IN PROGRESS** | [CI #38054012551](https://github.com/xxiamadelxx-blip/dice-metal-barbie/actions/runs/38054012551): D4/D6/D8/D12/D20 mathematics and actual physics checks green. D10/D100, large-N fairness, visuals, Android device and collision stress NOT VERIFIED. [Issues #12](https://github.com/xxiamadelxx-blip/dice-metal-barbie/issues/12), [#13](https://github.com/xxiamadelxx-blip/dice-metal-barbie/issues/13) |
| M4 Mechanics and state | NOT COMPLETE | Advanced formulas, rerolls, advantage/disadvantage, history, presets, persistence |
| M5 UX & Polish | NOT COMPLETE | Approved minimalist UI, actual sound/haptics, critical aura/flash, design review |
| M6 Release | NOT STARTED | Stable signing, on-device install/upgrade, FPS/long-run QA, GitHub Release |

**Do not claim M3 DONE based on 12/12, 10/10 or 8/8 stochastic trials. D4 is apex-read and has twelve face-attached glyphs.** These establish only basic simulation/face consistency under tested paths. Physical edge rests are handled via bounded actual impulses; any unresolved rest remains FAIL, not a fabricated die result. Independent UI review NOT VERIFIED.

## Priority policy 2026-10-11

**Current milestone: M3 (in progress).** M0/M1 approved; M2 automated PASS only. Earlier M5 Blender/Android prototypes are technical work ahead of sequence, not M5 acceptance. Avoid additional aesthetic-only passes until M3 and M4 functional criteria are met. Resume real sculpt/material/editor toolchain at M5, with approved reference comparison and physical Android evidence. M5 is mandatory **before** M6 release, not after publishing. Apply Gauntlet QA at every stage and retain M3/M4 development progress separate from M5 visual sign-off. `main` stays untouched until acceptance.

### M3 D10/D100 implementation candidate (2026-10-11; NOT VERIFIED until CI)
The next source revision introduces one parameterized mathematical trapezohedron generator: a dual antiprism with **10 faces / 12 vertices** for D10 and **100 faces / 102 vertices** for the single physical D100, all kite faces planar. A 100-sided body is *really* convex with 100 labelled physical faces, not a random number generator inside a D20 skin. The second D100 mode throws two independent physical D10 and calculates tens/ones from visible settled faces (printed 10 means digit 0; 00+0=100). Initial source authoring is **not** evidence of successful engine import or physically completed Jolt rolls. New geometry, real-physics and debug APK gates must pass; device legibility, efficiency and long-run statistical fairness are **NOT VERIFIED**. Cosmetic finish remains deferred to M5.
