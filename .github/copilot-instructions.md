# Gauntlet integration for coding agents

Apply to **all code/art/UX/test changes** in this repository.
This supplement exists separately from AGENTS.md to prevent conflicts with active parallel branches.

- Read `AGENTS.md` and the user's approved product decisions first.
- Read `docs/GAUNTLET_LOOP.md`, `docs/GAUNTLET_ACCEPTANCE_V2.md`, and `docs/GAUNTLET_AUTOPILOT.md` before implementing any substantial feature.
- For a scoped approved task, route build -> exact candidate SHA -> fixed tests -> fresh-context independent critic -> evidence-backed fixes -> rerun. Use `scripts/gauntlet_autopilot.py` and `.github/workflows/gauntlet-autopilot.yml` only when a truly authorized independent model endpoint is available.
- Preserve active Dice PR work; never overwrite another branch, change approved top-down design, or bypass Blender/Jolt temporal/Android QA.
- Missing reviewer/model/handset evidence => NOT_VERIFIED. Never treat self-review or a green contract regression as genuine independent critic approval.
- Work in isolated branch and propose draft PR; no automatic merge/deploy to main.
