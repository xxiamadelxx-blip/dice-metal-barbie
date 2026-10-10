# Milestones and exit gates

| Phase | Status | Evidence needed to pass |
|---|---|---|
| M0 | APPROVED | User-approved interview outcomes |
| M1 | APPROVED | User-approved Godot/Jolt architecture |
| M2 | AUTOMATED PASS · DEVICE NOT VERIFIED | [PR #1](https://github.com/xxiamadelxx-blip/dice-metal-barbie/pull/1), [CI #38043718230](https://github.com/xxiamadelxx-blip/dice-metal-barbie/actions/runs/38043718230): import PASS, 14/14 rules, 240 physics frames, APK artifact and debug JAR signature verified. [Device QA #5](https://github.com/xxiamadelxx-blip/dice-metal-barbie/issues/5) open |
| M3 | RESEARCH ACTIVE · NOT PASSED | [PR #6](https://github.com/xxiamadelxx-blip/dice-metal-barbie/pull/6) proves ideal D6 symmetry (149 checks); still requires real labeled die, real physics outcome agreement/fairness, D4/D100 and all shapes. [Hard gate #3](https://github.com/xxiamadelxx-blip/dice-metal-barbie/issues/3) open |
| M4 | NOT STARTED | All rules, formulas and persistence unit/integration tests green |
| M5 | NOT STARTED | Visual reference comparisons, sound/haptic hardware evidence, coherent UX |
| M6 | NOT STARTED | Nord 3 passes installation and upgrade, signed APK, reproducible export, GitHub Release |

No unverified gate is PASS. Document blockers and keep branch runnable. Acceptance details in `docs/ACCEPTANCE_CRITERIA.md`.

