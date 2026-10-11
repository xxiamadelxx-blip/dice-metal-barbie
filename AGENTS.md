# AGENTS — D&D 3D Dice

## Mandatory unified engineering entrypoint (all tasks and recovery)

For EVERY Dice coding, design, art, audio, security, architecture, performance, QA or release task, **and especially** when user says **«продолжай»**, **«завис»**, **«застрял»**, or asks to transfer to a **new agent**, use the **single canonical** `docs/ENGINEERING_ROUTER.md` and `config/engineering_routes.json` first.

1. Read `docs/handoff/ACTIVE_ROUTING_HANDOFF.json` and real current GitHub branch, PR, CI and accepted milestone (the saved state is a pointer, not necessarily current truth).
2. In an available terminal call `python3 scripts/engineering_router.py enter --intent "<literal user request>"`; for stuck work use `--intent "завис"`, for agent transfer call `python3 scripts/engineering_router.py handoff`. If no terminal is available, follow the same steps through GitHub repository reads and explicitly mark CLI `NOT_VERIFIED`.
3. Select only required route(s) and actually present tools; verify installation/execution/auth separately. Keep approved Godot/Jolt physics, offline Android and creative workflow from feature branch unchanged.
4. Run scope-matched tests + real artifact critique / independent Gauntlet when authorized. Never claim PASS for unrun checks, an absent external reviewer, or unavailable OnePlus Nord 3 hardware.
5. Before yielding, checkpoint exact task/route/SHAs/evidence/blockers/next action using `scripts/engineering_router.py checkpoint`, then **commit and push** the tracked `docs/handoff/ACTIVE_ROUTING_HANDOFF.json` to the relevant branch/PR. A local edit alone is NOT durable handoff.

Never create a competing agent runbook; update the canonical router, and preserve feature work. These rules apply from fresh sessions, not only the current chat.

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

