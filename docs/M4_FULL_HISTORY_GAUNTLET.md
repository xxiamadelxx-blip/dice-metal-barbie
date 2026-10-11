# M4 full local history viewer, not just two recent summaries

**Status:** independent full physical+UI native Godot QA **PASS** [#38128453601](https://github.com/xxiamadelxx-blip/dice-metal-barbie/actions/runs/38128453601), Android integrated history tap still unverified until exact-source full Gauntlet. The UI is deliberately subordinate to the approved minimalist top-down table.

## Actual user behavior
1. Open hidden upper-left **≡** advanced panel, tap **ИСТОРИЯ**. No account/network; all source data comes only from `RollPersistence.snapshot()["history"]`.
2. Browse every saved entry, up to the existing hard cap of **200** validated real Jolt casts (not 2). The newest result is selected first, and a scrollable `ItemList` allows selecting any other.
3. Search by formula text, numeric total or natural D20 critical status. The filtered list maps back to the real immutable stored entry, not an invented summary.
4. Read exact formula, total, signed modifier, D20 advantage/disadvantage and natural critical, each original dice group, individual dice and every actually recorded original and subsequently rerolled face in chronological order, including **two real D10 face digits** when the source is a physical paired percentile D100. A reroll or history search must NEVER choose a numeric result or rewrite the disk file.
5. Close the dialog and return to the tabletop; clearing history remains an independent confirmation dialog.

## Acceptance tests and Gauntlet
- `tests/m4_full_history_browser.gd` runs actual production `src/main.tscn` under Godot 4.6.3/Jolt: real mixed Jolt throw, actual source picker + physical reroll, real UI **ИСТОРИЯ** click, all saved records, face-by-face drilldown, positive and negative search and read-only recheck.
- `tests/m4_ui_temporal_capture.gd` records original source pixels through first throw, real clicked physical reroll, history dialog opening and final return to table. Native screen capture is **24fps nominal video**; `tools/visual/audit_m4_ui_frames.py` reopens every decoded original pixel frame, writes per-frame JSONL and 24 consecutive frame sheets per second. 24fps video cadence DOES NOT establish 24 unique hardware rendered frames.
- Do not promote to main PR until source-based independent QA PASS. After merge, unified Blender/MeshLab→Godot/Jolt→full native 24fps sets→Android emulator clicked UI and actual Android ARM64 debug APK must PASS on the exact merged source SHA. OnePlus Nord 3 on-device FPS + final M5 premium visual signoff remain open.

## Actual frame-based QA and next Android gate
In [QA #38128453601](https://github.com/xxiamadelxx-blip/dice-metal-barbie/actions/runs/38128453601), original real Jolt cast + true selected source reroll + full history popup worked end-to-end. 363 consecutive decoded frames, 16 complete chronological contact sheets, 92 moving frames, no black frames, two real source bodies retained, actual source D6 face 6→2, total 4→0, 19.1 effective Mesa engine-drawn FPS during physics (not Android). Independently viewed full-sized source frame containing full scrollable dialog and true per-die history. [Original artifact #11698495812](https://github.com/xxiamadelxx-blip/dice-metal-barbie/actions/runs/38128453601/artifacts/11698495812).

New Android `run_android_avd_rolls.sh` adds ONE MORE real tap after original physical pool and true selected D6 reroll: reopen drawer, tap `ИСТОРИЯ` near x540/y482 at the exact 720×1280 QA viewport, capture actual Android screenshot and require Godot's `DICE_M4_HISTORY_OPEN records=N` (N>=2) plus significant visual pixel difference from the drawer screenshot. Android `audit_android_avd_sequence.py` rejects any missing original/detailed history evidence and inspects every decoded 24fps M4 frame. This Android-specific gate must be confirmed with exact merged SHA. No OCR-based claim and no inference that the test video's nominal 24fps is target phone FPS.
