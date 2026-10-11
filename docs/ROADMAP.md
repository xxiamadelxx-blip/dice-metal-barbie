# Roadmap

**M0:** approved on 2026-10-10.
**M1:** Godot 4.6.3 / Jolt approved.
**M2:** cloud export and headless physics test automation passed; handset NOT VERIFIED.
**M3:** cloud mechanics/physical pipeline passed for D4/D6/D8/D10/D12/D20, single physical D100 and paired-percentile D10; real Jolt results and ARM64 debug export verified in [unified Gauntlet #38095490855](https://github.com/xxiamadelxx-blip/dice-metal-barbie/actions/runs/38095490855). Statistical fairness across every D100 face and actual OnePlus Nord 3 acceptance remain unverified. D4 uses its true top apex, not a fictitious upper face.
**M4:** **ACTIVE / NOT ACCEPTED**. Signed mixed groups, modifiers, actual-physics source rerolls, D20 advantage/disadvantage/crit behavior, local history/statistics/presets and touch-operated editor are implemented in draft PR #23. The combined [Gauntlet #38168476227](https://github.com/xxiamadelxx-blip/dice-metal-barbie/actions/runs/38168476227) passed native Godot/24fps/Jolt/ARM64 gates but failed strict original AVD pixels on D4-add screenshot captured before Android's redraw. Event-plus-rendered-pixel synchronization is patched; awaiting independent full regression before milestone closure.
**M5:** final minimalist UI, selectable cosmetics reserved for future, black obsidian/velvet material polish, spatial D20 crit aura/flash, realistic impact-driven sound and haptics.
**M6:** physical Nord 3 QA, stable protected signing key, reproducible production Android build, seamless updates preserving data, release notes and GitHub Release.

## Execution priority confirmed 2026-10-11

Active delivery gate is **M4 Android editor screenshot/temporal acceptance**: keep Godot telemetry AND enforce a distinct original framebuffer for every D4 add/remove, D20 sign/restore, Cancel/reopen, count and modifier tap. Rerun all eight real-physics Android cases and full 24fps/native/ARM64 checks at the new SHA, inspect the artifacts and independent Qwen 7B review if it actually runs; do not lower the original-pixel threshold to force green. Preserve completed M3 and old M5 experiments without treating either as device/visual release approval. Start M5 only after M4 passes its scope; M6 remains later.

Prior completed M5 experiments and issue #24 remain preserved in the draft PR, **ARTISTIC ACCEPTANCE OPEN**. Route every new asset through the exact `AGENTS.md` + `CREATIVE_TOOLCHAIN.md` tool selection; do not create purely performative editor jobs or conflate green automated QA with visual approval.

## Verified legacy HTML UX reference (2026-10-11)
The user-supplied *Adel Dice Roll Alpha 3 Obsidian Atelier* HTML was exercised in a real mobile Chromium browser (buttons, mixed pools, history, presets, sheets, menus), plus two genuine 24fps-cadenced screen captures and exhaustive frame sheets. Preserve transferable interaction patterns during **M4 mechanics** and **M5 interface polish**, but the approved Concept 3 visual authority is unchanged. See [the verified UX map](references/ALPHA3_OBSIDIAN_ATELIER_UX_AUDIT.md). This HTML is an interface reference only, not a D10/D100 physical result engine or approved 3D renderer.

Gauntlet Loop remains mandatory: artifact → actual test → independent critic where available → FAIL/FIX/RETEST, with real test evidence stored in PR.
