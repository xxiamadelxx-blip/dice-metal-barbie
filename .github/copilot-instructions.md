# Dice Roller: required engineering entry

Read `AGENTS.md` first and use `docs/ENGINEERING_ROUTER.md` as the **single canonical operational contract** for code, Godot/Jolt, modeling, audio, Android, security, architecture and agent recovery. Do not create another competing routing policy.

For **продолжай / завис / застрял / передача новому агенту**, load `docs/handoff/ACTIVE_ROUTING_HANDOFF.json`, inspect live GitHub HEAD/CI, and invoke `python3 scripts/engineering_router.py enter --intent "<literal request>"` if a terminal is available. If not, carry out the same read/dispatch/checkpoint from GitHub and disclose the unexecuted CLI.

For independent critique read `docs/GAUNTLET_LOOP.md`, `docs/GAUNTLET_AUTOPILOT.md` and `docs/GAUNTLET_ACCEPTANCE_V2.md`. Preserve existing product architecture and offline Android invariants. Exit after a real evidence-backed checkpoint committed/pushed to the correct PR, never after merely saying "waiting" or "done".
