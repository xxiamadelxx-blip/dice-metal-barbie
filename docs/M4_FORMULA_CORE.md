# M4, increment 1: pure composition of real physical outcomes

Stage: **SOURCE CANDIDATE**, not user-approved M4 complete. The existing Godot Jolt physics, dice and fixed top-down view remain untouched. No invented or synthetic result is shown to a user.

## Bounded formula grammar
`2d6+1d20-3`, `2d8-1d4-5`, `d20+7`, `1d100`. Allowed individual physical die types D4/D6/D8/D10/D12/D20/D100; 1-64 actual dice total, up to 12 grouped terms; signed dice-group arithmetic and bounded signed constants. Reject invalid grammar and unsupported D37 (the legacy Alpha 3 can pick arbitrary die sizes, but **this user's approved product** uses the standard seven physical types).

## No hidden random number generation
`src/core/roll_formula.gd:parse` only identifies requested physical groups. `evaluate` REQUIRES one actually observed Jolt face for every physical die; an optional list of genuine successive faces preserves manual reroll history. Missing or out-of-range physical faces cause an error, never silently filled by RNG or a fake animation.

For explicit D20 advantage or disadvantage, evaluate accepts TWO real D20 face values, selects higher/lower respectively, and computes `critical_d20` on the selected *unmodified* face. The formula's signed modifier never changes a critical value. If a mixed pool contains multiple separate D20 groups, crit and advantage require the player to explicitly select which D20 group is used (no silent first-20 choice).

Each successful result is an inspectable `schema_version=1` dictionary recording formula, modifier, individual dice initial/rerolled actual values, kept faces, signed subtotals, D20 mode, selected natural crit and final total. The source is not an automatic persistence/release guarantee until history/presets are built in later M4 substeps.

## QA
`tests/m4_roll_formula.gd` exercises parsing, positive/negative terms, mixed groups, signed modifiers, physical reroll histories, D20-only advantage/disadvantage, selection ambiguity, natural crit semantics, valid D100=100, invalid syntax/faces and missing physical observations. Tests use **explicit oracles only**, not claimed live physics. Existing 8-mode Jolt/Android Gauntlet still validates actual physical animation and face consistency. Full M4 UI, multi-body Jolt orchestration, wiring the verified offline history/preset store into user-facing controls, and responsive panels remain **NOT DONE**.

## UX adaptation from legacy Alpha 3
The user's [audited Alpha 3](references/ALPHA3_OBSIDIAN_ATELIER_UX_AUDIT.md) establishes *interaction patterns only*: quick default die choice, secondary explicit "add to pool", collapsed advanced formula editor, clear count/modifier stepper, local history/presets and accessible bottom sheets. The approved Concept 3 black-obsidian visual and overhead camera remain authoritative. Do NOT copy low-contrast buttons, shop placeholders, synthetic physics or arbitrary D37 dice.

## Offline M4 state, implementation candidate (2026-10-11)
`src/core/roll_persistence.gd` implements **user://dice_state_v1.json** (schema v1), bounded **200 latest physical results** and **40 named presets**, with safe temporary write + same-directory rename, reload-after-restart, edit/apply-ready formulas, and explicit confirmation before clearing history or deleting a preset. A malformed or unknown-schema file is NOT silently overwritten; storage becomes read-only until recovery.

The write boundary recomputes totals, signed subtotals, D20 natural critical semantics and each recorded sequence of real physical faces through `RollFormula.evaluate`, rejecting altered/missing trace data. For percentile D100, `percentile_source_d10_faces` stores the TWO actually observed physical D10 values (1..10 where face 10 represents printed 0) and the derived D100 total, so `00+0=100` is reconstructible after reloading the history. Neither a mere source-label string nor a UI animation is proof that Godot/Jolt produced a given face: integration must call this only from the actual physics-completed controller.

`tests/m4_roll_persistence.gd` creates an isolated local test file, checks actual write/reopen, edit/delete preset, confirmation barriers, file corruption preservation, rejection of tampered totals and percentile source faces. QA runs are isolated from normal app data. **No Android UI/history/preset buttons have been shipped yet.** Next M4 integration must drive multiple genuine Jolt rigid bodies, keep 24fps frame receipts, implement the collapsed Alpha 3-inspired panel, and bind this versioned store. Full M4 acceptance stays OPEN.
