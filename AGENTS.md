# AGENTS — D&D 3D Dice

Read `docs/CONTEXT.md`, `docs/PRD.md`, `docs/ARCHITECTURE.md`, and `docs/GAUNTLET_LOOP.md` before significant changes.

Product and architecture were approved 2026-10-10. Never rewrite approved product decisions (top-down orthographic view, offline, obsidian/velvet, visible face = outcome, D100 two modes) without user consent.

## Required Gauntlet Loop (M2 onward)

LEAD → BUILDER → INDEPENDENT CRITIC (when actually available) → COMPARISON → FIX → REPEAT → INTEGRATION.

- Define objective, a real artifact, measurable acceptance and an appropriate reference for every task.
- Run engine/tests/export as applicable. CI green is necessary, **not sufficient**.
- Critic must inspect actual implementation/results, not builder's narrative. When no separate critic is available, mark `NOT VERIFIED`, never counterfeit independence.
- Record evidence in PR/Issues; fix failures and rerun.
- Do not invent test pass, FPS, APK, device checks, security validations or completed features.
- Final release requires on-device Nord 3 installation, offline, face consistency, statistics, signing and upgrade testing.
- No paid tools, cloud runtime, account flows, or third-party assets without approval/license.

Use feature branches and PRs. Do not push unreviewed work directly to `main` unless explicitly authorized. Never commit signing keys or passwords.

For all new substantial candidate acceptance reviews, apply the fail-closed independent evidence contract in `docs/GAUNTLET_ACCEPTANCE_V2.md` and verify it with `scripts/gauntlet_evidence.py`. This adds to, never replaces, the existing visual/temporal/Android Gauntlet or other agents' active work.
