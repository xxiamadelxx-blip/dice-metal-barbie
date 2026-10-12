# Actual engineering entry audit, 2026-10-13

Base PR23 source: `c0cf743ed40284161d7f03ad327230a190c09f6a`; main unchanged.
User asked that a new agent execute the toolchain, engineering router, Gauntlet and Qwen rather than merely read their names.

## Root cause
`engineering_router.py enter` printed JSON only. `audit` checked PATH only.
The unified asset/runtime Gauntlet did not depend on an executed engineering entry or Qwen reviewer.
Existing Qwen workflows reviewed specific M4 scripts only on narrow path triggers.
Therefore reading AGENTS or passing router validation did not start the promised checks.

## Change
The SAME canonical `enter` now executes bounded local router/Gauntlet tests,
architecture/security checks and installed binary version commands; retains raw logs
and `entry-report.json`. Local Qwen7B runs only when installed and the candidate is committed.
Missing models are NOT_VERIFIED. `--inspect-only` is explicitly not execution.
Unified CI prepares the existing local Ollama setup and requires an actual SHA-matched
Qwen source response before the existing Blender/native/24fps/Jolt/ARM64/AVD graph.
Raw independent response is retained; findings must be triaged, not auto-approved.
No new paid provider, runtime service or changes to dice outcomes.

## Actually executed locally
- Engineering tests: 22/22 PASS, including new failed-process/missing-tool evidence regressions.
- Gauntlet contracts: 25/25 PASS. These are contracts, not real model execution.
- Security: PASS_PATTERN_ONLY, 52 source files, no pattern findings. Not full security certification.
- Architecture: FAIL, 30 sources and 61 literal edges. Existing forbidden dependency
  `src/core/physical_roll_pool.gd` -> `src/visual/critical_aura.gd`.
  This remains a blocker; do not hide it or weaken the architecture analyzer.
- FFmpeg and Inkscape: actual version commands exit 0. Not production exports.
- Blender/Godot/ADB/Ollama: absent in this environment; NOT_VERIFIED locally.
- Qwen: NOT_VERIFIED locally. Added mandatory cloud route is not a claim it already ran.
- Full render/Android/handset quality: NOT_VERIFIED by this governance change.

Original user premium-materials research already exists in
`docs/research/DICE_ROLLER_FREE_PREMIUM_MATERIALS_RESEARCH_PLAN.md`.
Uploaded copy is identical apart from its final newline. It is a PLAN, not completed artwork.
Current D20 source-first/private-asset handoff remains intact; M5 art and M4 AVD regressions stay open.

## Next action
Run the unified CI on the committed change; inspect `engineering-entry-and-qwen`.
Triage architecture dependency and raw Qwen findings before promoting full Gauntlet.
Continue exact Codex D20 source integration only with actual GLB/Jolt/Android evidence.
No automatic command can compel a separate chatbot to obey AGENTS; this repository now
provides an executable route and CI gate instead of claiming such enforcement exists.
