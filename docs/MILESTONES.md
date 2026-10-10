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
