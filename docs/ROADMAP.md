# Roadmap

**M0:** approved on 2026-10-10.
**M1:** Godot 4.6.3 / Jolt approved.
**M2:** cloud export and headless physics test automation passed; handset NOT VERIFIED.
**M3:** **active; five numbered Jolt dice D4/D6/D8/D12/D20 implemented, CI verified** ([CI #38054012551](https://github.com/xxiamadelxx-blip/dice-metal-barbie/actions/runs/38054012551)). D4 uses top-apex repeated numerals, not a fictional top face. Remaining: D10, D100 as real single polyhedron plus percentile pair, higher-load multi-die physics, long-run fairness, visual/glyph on-device captures and audio/haptic physical contact design. Issues #3, #12, #13.
**M4:** mixed groups, full expressions/modifiers/rerolls, D20 advantage/disadvantage and natural critical rules, local history/statistics/saved combinations.
**M5:** final minimalist UI, selectable cosmetics reserved for future, black obsidian/velvet material polish, spatial D20 crit aura/flash, realistic impact-driven sound and haptics.
**M6:** physical Nord 3 QA, stable protected signing key, reproducible production Android build, seamless updates preserving data, release notes and GitHub Release.

## Execution priority confirmed 2026-10-11

Active delivery gate is **M3 PARTIAL**. Finish missing physical D10, both D100 modes (actual D100 and two percentile D10s), multi-die stability and higher-volume fairness/invariants before declaring M3 done. Then M4 mechanics and offline state/history/presets. Schedule the premium black-obsidian/velvet finish, sound/haptics and final user-approved Concept 3 comparison during M5 rather than blocking every M3/M4 functional increment on nonessential art. M6 depends on M5 and hardware QA and cannot precede them.

Prior completed M5 experiments and issue #24 remain preserved in the draft PR, **ARTISTIC ACCEPTANCE OPEN**. Route every new asset through the exact `AGENTS.md` + `CREATIVE_TOOLCHAIN.md` tool selection; do not create purely performative editor jobs or conflate green automated QA with visual approval.

Gauntlet Loop remains mandatory: artifact → actual test → independent critic where available → FAIL/FIX/RETEST, with real test evidence stored in PR.
