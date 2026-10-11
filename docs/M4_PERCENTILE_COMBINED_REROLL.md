# M4 percentile selection modes · Gauntlet candidate

The source PR already implements physically correct individual *tens* and *ones* D10 rerolls. This QA branch **adds**, rather than replaces, the D&D-standard option to reroll the **whole logical D100**, which genuinely moves BOTH of its original numbered D10 bodies simultaneously.

User-facing M4 advanced reroll menu for each physical 2-D10 percentile D100:
- **ОБА физических D10**: both source rigid bodies receive real Jolt launch forces, and both are checked again for final sleeping top face and original callbacks.
- **Десятки D10**: only the tens source rerolls, the ones source remains frozen at its actual upper face.
- **Единицы D10**: only the ones source rerolls, the tens source remains frozen.
Other dice and other D100 pairs stay on the table, and none of their genuine values change. A single physical convex D100 still rerolls as one die.

The original schema-v1 persisted record's `percentile_source_d10_attempts` retains chronological raw face pairs (including any prior single-digit steps). A new **optional** per-source `percentile_reroll_modes` field is emitted ONLY after explicit modes exist and distinguishes `one` and `both` transition steps. Missing action metadata keeps the previous strict rule: no step may change two digits. The independent offline persistence replays all per-step actions, rejecting tampered/unsupported masks, numeric totals and impossible Jolt faces. Prior history files are readable without destructive migration. Real-time gameplay remains offline; no synthetic result is generated.

**QA evidence required**: actual Godot/Jolt physical 3-body and 5-body casts; after one logical D100 rerolls both source D10 bodies together, verify other physical rigid bodies and source face traces stay unchanged; then verify single-digit rerolls still work after a whole-pair reroll. Actual GUI pick and offline history source detail; identical full chronological 24fps pixel capture with original and new paired D10 and real history popup; whole-source PR Gauntlet through Blender/MeshLab, eight native and Android videos and ARM64 APK. User's OnePlus device FPS and M5 approved visuals remain NOT VERIFIED until separately tested.
