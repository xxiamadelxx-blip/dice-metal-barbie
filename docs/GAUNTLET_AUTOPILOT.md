# Autonomous Gauntlet: real builder / isolated critic / fix-and-retest

This implementation is a bounded **execution system**, not just a checklist. It is an additive agent role inside the canonical project bootstrap; never replace product acceptance, specialist tests, the DM runtime anti-stall controller, or Dice's unified Blender/Godot/Jolt pipeline.

## How it runs

1. An already-approved owner-maintained task manifest is committed under `qa/gauntlet/tasks/<task>.json` with exact existing source files (max 8), required `acceptance`, a raw `approved_reference`, fixed test argv, `repository` and iteration budget (1–3). Discovery/user design approvals precede this.
2. A dispatcher checks out a trusted commit and creates its **own** `gauntlet/autofix-<run>` branch. The Python runner refuses a dirty checkout and refuses to edit `main`/`master`. It does not edit any currently active contributor feature branch.
3. **Builder** makes one fresh stateless AI request, with only the allowlisted original source and prior critic findings. It may return only complete replacement texts for already-present allowlisted source files. No commands or extra paths are accepted.
4. CI runs the **fixed owner-selected test command** with provider and GitHub credentials removed from child process environment. Each candidate is committed locally with a new Git SHA. Its raw diff and raw test output are captured.
5. **Critic** receives a separate stateless AI call, only the approved criteria, actual candidate SHA/diff, test output and prior unresolved critic findings, never the builder's self-reported narrative. It reports explicit ranked defects or PASS. Both requests and answers are stored as raw artifacts. Reviewer mode is marked independent only if the authenticated separate response actually arrived.
6. Builder fixes observable defects, **new source SHA**, repeats tests and fresh critic; at most three iterations. Critical findings remain open until the critic explicitly marks the same ID resolved with real new evidence. No silent downgrade to PASS.
7. `scripts/gauntlet_evidence.py` rechecks the complete trail and final exact SHA. The workflow can push the accepted local commits **only** to a fresh `gauntlet/autofix-...` branch and proposes a **draft PR**; it never merges, deploys, changes a live database, uses an existing feature branch as a write target, or declares Android/UX release readiness.

## Provider is mandatory (no pretend AI)

GitHub Models inference was retired 30 July 2026. The workflow cannot use `models:read` as an imaginary free model. The local runner uses a configured **OpenAI-compatible HTTPS chat-completions endpoint**; its runner process needs:

- `GAUNTLET_AI_URL`: absolute HTTPS chat completions endpoint (GitHub Actions **repository variable**).
- `GAUNTLET_BUILDER_MODEL`, `GAUNTLET_CRITIC_MODEL`: explicit supported IDs (**repository variables**).
- `GAUNTLET_AI_TOKEN`: personal/repository-provided provider token (**Actions secret**, never in git).

Missing/unauthorized/rate-limited endpoint => **NOT_VERIFIED**, not success; no fallback that invents a critic. Do not auto-open paid API accounts, change subscriptions or transfer existing DM provider credentials. For a repository that cannot use GitHub Actions due to billing, run the same Python CLI in an authorized isolated Codex/Codespace runner and keep logs locally; no PC on the user's side is required. Never run this against user content with an unapproved third-party provider.

## Example owner-approved task file

The example below is **illustrative**, not an authorized task: choose a real existing source path, test command and approved reference from that project's current roadmap before committing it.

```json
{
  "repository": "OWNER/REPO",
  "task": "Precisely scoped approved change",
  "approved_reference": "docs/PRD.md#approved-criteria",
  "acceptance": ["Observable behavior one", "Regression two"],
  "allowed_paths": ["existing/source/file.py"],
  "test_command": ["python3", "-m", "unittest", "tests.test_exact_feature"],
  "test_timeout_seconds": 180,
  "max_iterations": 2
}
```

Local isolated invocation:

```bash
git checkout -b gauntlet/autofix-my-task
python3 -m unittest discover -s tests -p 'test_gauntlet_*.py' -v  # dice
# OR on DM: python3 -m unittest discover -s scripts/tests -p 'test_gauntlet_*.py' -v
python3 scripts/gauntlet_autopilot.py --root . --spec qa/gauntlet/tasks/approved.json --out /tmp/gauntlet-proof
python3 scripts/gauntlet_evidence.py /tmp/gauntlet-proof/gauntlet-record.json --expected-sha "$(git rev-parse HEAD)" --repository OWNER/REPO
```

For GitHub Actions, dispatch `.github/workflows/gauntlet-autopilot.yml` from the **trusted default branch** with the task file path. This is intentionally manual/agent-dispatched rather than creating a costly/unsafe CI storm for every existing concurrent PR. The task's owning agent should dispatch it as part of its review gate when provider access is authorized. Normal narrow tests continue independently.

## What PASS does and does not mean

PASS establishes a real two-context model review and the fixed test suite for exactly one proposed source SHA, with a saved review record. It is **not** a guarantee that models are correct or identical to a separate human reviewer. It is not proof that a 24fps video has 24 unique engine-rendered frames, that every screenshot was artistically examined, that model-generated prose is canonical D&D state, that production owner authentication works, or that OnePlus Nord 3 runs at target FPS. Those gates must be separately configured, run and evidenced before release.

**Concurrent work:** existing PRs remain untouched; no force push, no auto-merge. Merge/update only once the exact main/PR HEAD has been reconciled; use one integrator per shared file, and keep any unresolved external action in NOT_VERIFIED state.
