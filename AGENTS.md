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


## Autonomous Gauntlet mandate (user instruction 2026-10-10)
Apply the loop to **every implementation change**, including art, UI, automation and builds, without asking the user to act as an iterative critic. The agent must own the compare/fix/retest decisions and prioritize the approved concept and running artifact. For high-impact work, set acceptance before coding, inspect raw engine output and record concrete defects. If independent reviewers are unavailable, perform explicit adversarial self-review using actual screenshots/logs and mark independence unverified; never fabricate a second agent.
Do not gate ordinary iteration on user responses. Escalate only necessary approvals, missing secrets or actual handset actions that cannot be performed autonomously. Keep draft PRs unmerged until unresolved device/release gates have real evidence. If a specific test cannot be run, record NOT VERIFIED, not PASS.
