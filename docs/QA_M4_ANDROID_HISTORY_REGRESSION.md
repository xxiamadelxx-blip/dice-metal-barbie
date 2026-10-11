# M4 Android history click Gauntlet regression: confirmed false red and durable correction

**Observed on 2026-10-11.** Previous exact-source full [Gauntlet #38130611507](https://github.com/xxiamadelxx-blip/dice-metal-barbie/actions/runs/38130611507), source SHA `7efc8b2cbb64c282e0c4553a2bfa10ab72c48e22`, correctly returned **FAIL** because its automation contract was incomplete. Do NOT change that historical run to PASS.

## Verified from ORIGINAL recorded evidence

[Archived failed Android video and raw screenshots](https://github.com/xxiamadelxx-blip/dice-metal-barbie/actions/runs/38130611507/artifacts/11698538510) were downloaded and the exact five ADB screenshots reviewed visually, including original before-history state, reopened advanced panel, the actual full history modal, the previous reroll selector and the real post-tap screen.

The actual Android app succeeded:
- `DICE_M4_PHYSICAL_STARTED 2d6+1d20-3` and `SIMULTANEOUS_STARTED=3` (real Jolt bodies).
- `SIMULTANEOUS_COMPLETED=3`, first actual total **13**.
- `DICE_M4_REAL_REROLL_STARTED group=0 die=0`, `DICE_M4_REAL_REROLL_COMPLETED D6=4 attempts=2`, subsequent total **12**.
- Screenshot **m4-full-history-open.png** visibly showed a true modal titled “ИСТОРИЯ ФИЗИЧЕСКИХ БРОСКОВ”, 10 saved physical records, a scrollable list, original-plus-rerolled source faces and row detail, signed subtotals, and a Close control.
- Failed-run diagnostic decoded **982 original frames**, 91 with changed physical-stage pixels, **zero black**. No claims of actual 24 unique GPU FPS.

The test itself required both a changed real screenshot AND log event `DICE_M4_HISTORY_OPEN records=N`. The old `src/main.gd:_open_m4_history()` opened the popup **but never emitted this event**. The runner was red exclusively at the missing telemetry sentinel even though the original screenshot independently proved the correct history UI was on screen.

## Code fix, not test relaxation

At the end of the genuine `_open_m4_history()` UI method, after its `history_dialog.popup_centered_ratio(0.88)`, verify `dialog.visible` and `visible_record_count == offline_history.size()`. Only then print the original required `DICE_M4_HISTORY_OPEN records=N` event in debug builds. If display or population fails, emit Godot error instead.

**Preserve both gates** in `tools/visual/run_android_avd_rolls.sh`: 1) actual ADB tap and Godot event **N >= 2** for original + reroll; 2) real before/after Android screenshot pixel-difference threshold **more than 15,000 changed pixels**. Preserve original MP4, screen and error logs even on any failure. Neither reduce thresholds nor assert success based on an unverifiable synthetic event.

[Isolated actual-Godot QA](https://github.com/xxiamadelxx-blip/dice-metal-barbie/actions/runs/38132246914) repeats actual Jolt physical cast, actual user reroll, and real full-history click, and greps for the precise new debug event. After this succeeds, push into existing draft PR #23 (never main), let the complete Blender/MeshLab → Godot/Jolt → ARM64 APK → eight native physical videos plus real clicked Android history-and-reroll 24fps original video Gauntlet run again. Do not claim integrated Android PASS until the NEW run finishes. Keep all-original pixel Gauntlet and Godot model evidence.

### Visual caveats

While the popup is functional, raw screenshot still reveals small, dense list/detail typography at **720×1280**; the current dark die materials and handfeel remain well short of the user-approved premium Concept 3. M5 is responsible for professionally designed type hierarchy, die engravings, tactile effects, and near-real-60fps device acceptance. The current screenshot is not final art approval.
