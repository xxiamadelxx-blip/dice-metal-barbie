# M4 physically correct composite pool editor: Gauntlet candidate

Approved functional scope only. The minimal playfield/camera and old D100 source controls are unchanged.

- The advanced drawer's existing formula field shares its original vertical row with a **НАБОР** button. The editor is a hidden modal, not a new always-visible menu or unfinished art/skin module.
- The player can choose D4, D6, D8, D10, D12, D20 or D100, add/remove signed groups, increment/decrement a group's real dice count and the flat modifier. Source `src/core/roll_pool_builder.gd` delegates every candidate to `roll_formula.gd:parse` and never uses random number generation. Invalid/over-limit edits are rejected atomically, preserving the valid expression.
- Application through the real modal OK button writes *only* the normal formula field. Cancel/invalid free text must not rewrite a player formula. Godot/Jolt is still the only source of numerical results once the normal throw button is used.
- Presets keep their existing semantics: saved formula applies to the existing field; opening the composer reparses the current field. D100 source body mode stays in the existing paired/single selector. Natural D20 critical rules stay unchanged.

**Acceptance for this candidate, not yet verified**: source grammar boundary and cancellation, real UI buttons (group sign/count, types and modifier), actual four-body physical signed Jolt throw with source total/persistence, all existing 8 original roll types including actual AVD D100 source rerolls, and complete 24fps native video expanded to show modal editing. Current software renderer screenshots are not real OnePlus Nord 3 on-device FPS. Full combined Gauntlet required before M4 functional acceptance. No change to M5 art, sound, haptics or release signing.
