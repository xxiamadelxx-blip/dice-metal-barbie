# M4 live physical mixed rolls · Gauntlet candidate

## What is implemented (and NOT implemented)
- Reuses **real Godot 4.6.3/Jolt rigid bodies** for D4/D6/D8/D10/D12/D20/single-D100; paired percentile uses **two concurrently moving real D10**. Never picks, fabricates or assigns a hidden outcome.
- One actual 120-Hz Jolt simulation cycle launches **all** selected sources in separated x/z positions with their native physics launch orientation/impulse/torque unmodified. No earlier die is removed at the next source: all valid settled bodies remain on the table until an explicit new throw, and any disagreement between a final uppermost face, original Jolt callback or rigid-body result fails the entire cast. The production tabletop currently bounds at **eight** concurrently instantiated physical bodies; a paired D100 consumes two bodies. This is the first simultaneous implementation and its real Android/GPU acceptance is separate.
- Each Jolt body emits an actual `roll_completed` event, which the controller checks a second time against its real top-facing normal and settled body property. An edge rest, timeout, invalid face or physical body error fails the ENTIRE composite roll. Never silently discards a failed die or substitutes random digits.
- D20 advantage and disadvantage require **two genuine D20 physical bodies**, rolled together, with the selected raw face checked against the real body. A natural 1/20 triggers the existing critical aura *on the chosen physical D20 body itself*, not the sum or an unchosen second D20. Exact cue timing/artistic polish is an M5 review gate.
- Formula accepts up to 8 physical user-selected standard dice per mixed throw at this stage, while general pure parser allows 64. This deliberately conservative collision/performance bound is not a D&D rule.
- Actual runtime-only `OpenAdvancedRules` small left-top button opens a collapsible drawer with editable formula, D20 normal/adv/disadv, D100 pair/single, stored presets and two most recent results. It is a functional interim stage, NOT the final approved M5 premium treatment.
- Visible launcher closes the drawer, prevents unwanted navigation during roll, restores controls after real settlement. Incorrect syntax is refused **before removing the previous valid die/result**.
- Both simple and mixed completed real throws enter the **offline versioned history**, including both independent tens/ones D10 faces for 00+0=100. Presets save/apply/delete and clear history require confirmation for destruction. No backend, tracking or registration.

## M4 QA protocol (actual engine, no fake screens)
- `tests/m4_physical_pool.gd`: genuine concurrent physics for mixed D6/D20, physical D100+D4, D20 advantage, **8d6**, and **2d100+1d4** (two independent percentile pairs). Verifies every source against its true upper face, original Jolt callback, rigid-body state, **concurrent motion** and preserved on-table body count. Physical expected RESULTS are never preselected. Includes consecutive true throws to detect deferred SceneTree deletion regression.
- `tests/m4_advanced_ui_integration.gd`: instantiate the REAL scene, open drawer by button signal, type a formula, store/reapply a named preset, press actual physical roll button, await Jolt, compare total against physically recorded groups, check persisted history after reopening file.
- `tests/m4_ui_temporal_capture.gd` + `tools/visual/run_m4_ui_capture.sh`: real visible 720x1280 Godot window, FFmpeg X11 capture 24fps (capture cadence only), READY/GO/DONE/SAVED handshake across menu opening, formula click, complete actual Jolt physics and settled result.
- `tools/visual/audit_m4_ui_frames.py`: decode **every** original screenshot sequentially; per-frame JSONL, changed pixels, black-frame check and ALL **24 consecutive captured frames** for every recorded second. Preserve uncropped MP4 and logs in artifact. This is **Linux Mesa**, not an Android phone.
- Existing main PR unified Gauntlet must still re-run Blender/MeshLab fresh GLBs, native 8 original physical throws and exhaustive frame sheets, Android 8 AVD videos, and ARM64 APK against the SAME new source revision.
- **Still OPEN:** exact revised Android M4 **simultaneity** and actual smartphone FPS/UI tap acceptance; live select-one-die physical reroll and full history view/filters/statistics; M5 premium art, readable D100 engraving, contact audio/haptics. One green desktop video is not artistic sign-off.

## References
- Product authority: `docs/PRD.md`, `docs/DESIGN.md`, `docs/ACCEPTANCE_CRITERIA.md`.
- UX behaviors: `docs/references/ALPHA3_OBSIDIAN_ATELIER_UX_AUDIT.md` (the provided HTML reference DOES NOT replace our approved physical or visual design).
- Gauntlet: `docs/GAUNTLET_LOOP.md`, `docs/QA_M3_FRAME_SETLIST.md`.
