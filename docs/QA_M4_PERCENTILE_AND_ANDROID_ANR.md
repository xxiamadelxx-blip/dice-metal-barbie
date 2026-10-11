# M4 paired-percentile source reroll and Android launcher ANR Gauntlet

2026-10-11. **M4 active, PR #23 DRAFT; main not merged.** Do not treat a green native render as a smartphone QA result.

## Grounded result of previous exact-source Gauntlet

- [#38132510403](https://github.com/xxiamadelxx-blip/dice-metal-barbie/actions/runs/38132510403): prior physical D6 selective reroll and full Android history UI passed all nine unified gates. Full M4 feature set and real phone not thereby accepted.
- [#38133903845](https://github.com/xxiamadelxx-blip/dice-metal-barbie/actions/runs/38133903845): new separate D100-tens/ones source feature passed physical Jolt/unit, Blender, native, APK build checks; the overall Gauntlet **FAILED** Android AVD launch readiness. Do not relabel it PASS.
- **Original archived Android evidence:** [artifact #11700900659](https://github.com/xxiamadelxx-blip/dice-metal-barbie/actions/runs/38133903845/artifacts/11700900659), not-ready screenshot 3 and launcher consent screenshots. The game is visibly rendered BEHIND a system modal reading "Pixel Launcher isn't responding"; ActivityManager logs `ANR in com.google.android.apps.nexuslauncher`. The fullscreen tutorial had been dismissed correctly. The modal was not, leaving repeated game-stage-readiness statistics (mean 22.08, std 5.87) for 100 s. This is **system launcher ANR interference**, not proof the Godot scene failed or a valid Android visual PASS.

## Corrective Gauntlet implementation (requires a NEW run)

1. Only accept Pixel Launcher ANR dismissal when the ORIGINAL ADB screenshot meets the known Android-system-card pixel geometry AND logcat reports an actual `com.google.android.apps.nexuslauncher` ANR. Tap the original **Close app** row at (250,650), not a gameplay element. Never dismiss a Godot-app ANR; those remain a fail.
2. Check again in each launch-readiness iteration. After dismissal demand the unchanged original image-based game-render threshold. Do not loosen brightness, black-frame, animation, physical result, or 24fps per-frame gates.
3. Record full source-pair history for selected original D100 tens and ones. No virtual face substitution. The menu explicitly lists both physical D10 source bodies; only the chosen rigidbody is released on reroll, other actual dice remain fixed.
4. Real Godot UI click-through and Linux/Mesa temporal capture now include consecutive **tens AND ones** selective throws, table-visible original bodies, saved history detail, original video, all frames, and 24-frame sheet per second. Separate Android baseline M4 physical D6 click/history gates remain mandatory; these are NOT a completed Android paired-D100 player-click validation.
5. Every historical/current result must be based on actual settled Jolt upper faces and preserved chronological source-digit pairs; offline integrity refuses impossible transitions and tampering. Old schema-1 data remains readable.

## Acceptance before merging

- Full unified Gauntlet on the new exact code/GLB set PASS, including Android AVD actual game and all 8 baseline original recorded Jolt rolls, M4 physical D6 touch/reroll/history and valid ARM64 build.
- Native player-facing selected paired-D100 controls + 24fps original frame capture both pass.
- **New candidate:** a dedicated original Android ADB touchscreen source-dropdown walkthrough for paired tens and ones plus separate uncut recorded video, every-frame JSONL and 24-frame contact sheets has been authored, but is **NOT VERIFIED** until the next exact-source full Gauntlet. Physical Nord 3 install, fps and aesthetics remain NOT VERIFIED. M5 final art/UX/audio and M6 release are not ready.

## Last integrated Gauntlet: AVD paired-D100 failure and next independent retest

[Full #38135657551](https://github.com/xxiamadelxx-blip/dice-metal-barbie/actions/runs/38135657551) **FAILED** at NEW Android player-selected physical D100 pair source walkthrough (exit 21, `FAIL: player Android D100 pair formula`). The eight original Android rolls, real mixed-D6 source reroll and clicked full history ran, while Blender/MeshLab, real Jolt, native all-24-frame setlists and ARM64 APK gates passed. Extra pair video diagnostic recorded 3,223 decoded frames, eight changed, four black and NO genuine paired completion. The separate script relaunched Android then blindly slept 8 seconds before clicking; it lacked the prior original AVD readiness gate. New source hypothesis: wait for the established real playable 720x1280 stage pixel criterion after restart (up to 20 checks with 5s delay), retain each non-ready screenshot and logcat, fail closed if never ready. This fix is **NOT VERIFIED** until a fresh same-source, genuine Android D100 tens/ones touchscreen Gauntlet. No fake Jolt outcome, reroll signal or Android FPS pass.
