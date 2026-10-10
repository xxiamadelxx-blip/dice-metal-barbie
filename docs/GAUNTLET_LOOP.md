# Matt Shumer-inspired Gauntlet Loop: operational procedure

After M0 and M1 approval:
1. **LEAD:** describe objective, approved reference, artifact and measurable acceptance criteria.
2. **BUILDER:** deliver actual code/model/scene/test/APK.
3. **CRITIC:** independent reviewer if available, **fresh context**, only artifact/tests/references, no builder justification. Otherwise use automated checks plus transparent self-review, mark independence NOT VERIFIED.
4. **COMPARISON:** factual PASS / FAIL / NOT VERIFIED per criterion. Fail includes reproducible defects.
5. **FIX → REPEAT:** fix highest-impact root cause, rerun checks, reevaluate; no artificial three-iteration cap. Stop/report if objective blocker or diminishing progress.
6. **SMOOTHING:** check full app consistency, UI, audio, states, physics, persistence and performance; run regressions.

For each substantial PR, include: scope, reference, exact tested commit, commands/results, links to Actions logs and artifacts, user-device evidence if present, critic status, unresolved blockers. An unrun test MUST be NOT VERIFIED, never PASS. A successful compile alone cannot pass an app milestone.

Validation levels:
- Numeric: test oracle, boundary and chi-square tests; no claim of absolute randomness.
- Physics: real bodies, collisions, deterministic scenario playback, movement bounds, visual face mapping.
- Visual: actual captured video/screenshot compared with approved design; don't grade a mockup as a running screenshot.
- Android: successful CI export, actual installation and later stable-key update test.

