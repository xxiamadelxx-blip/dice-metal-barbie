# Adel Dice Roll Alpha 4.0.0 Live · Obsidian Studio — M5 reference audit

**Reviewed:** 2026-10-12. **User reference:** https://adel-dice-roll.vercel.app/ . **Role:** aesthetic, interaction and VFX reference for the **separate** Godot/Jolt offline Android Dice Roller; NOT a replacement runtime or new source of truth. User explicitly likes this earlier project.

## Provenance and verification boundary

- Live Vercel deployment returned **HTTP 200**, title `Adel Dice Roll · Alpha 4.0.0 Live · Obsidian Studio`. Vercel deployment `dpl_CZWSQdu6g2NJamwrrkbMcN8M2iUY` READY, linked to owner's **separate** repository `xxiamadelxx-blip/Dmmaster`, source revision `8692a682fe34ccc855a0550bf7747eff8846ed29` on `main`. HTML returned by live Vercel connector is ~16.65 MB, with embedded CSS/assets and Three.js r184 loader, plus 2D fallback.
- Reviewed actual served HTML/CSS and source `src/alpha4.css`, `src/critical-effects.mjs`, `src/critical-feedback-runtime.mjs`, `src/ui-contract.mjs`, `src/settling.mjs`, `docs/superpowers/specs/2026-08-12-alpha-4-live-design.md`, and `docs/ops/PRODUCTION_BASELINE.md`, at that exact Dmmaster commit.
- The browser automation execution **did not start** because its TinyFish wallet was out of funds. Consequently no new, verified live-interaction screenshots, touch videos, frame-by-frame Three.js captures, audio auditions, or hardware UX claims were made. The findings below are **served-source and verified design-code findings**, not a fabricated hands-on screenshot report. HTTP 200 / served DOM != working JS/WebGL.
- Previous separate `docs/references/ALPHA3_OBSIDIAN_ATELIER_UX_AUDIT.md` tested an EARLIER Alpha 3 in actual Chromium but only its 2D fallback (Three.js CDN unavailable). Do not relabel Alpha 3 screenshots as Alpha 4 evidence.

## Why this is a strong visual reference

| Visible source styling / component | Reference behavior and values | Transfer to current M5 |
| --- | --- | --- |
| Obsidian Studio palette | Warm black/jade background (`#080b0a` and surface `#0f1412`), aged brass `#c4a164`, champagne-highlight `#ead49d`, quiet jade `#477b70`, ivory serif for important result. Restrained seams and diffuse light. | **HIGH**. Adapt restrained jade/brass warmth to approved black-velvet/obsidian Godot 3D, but do not replace premium PBR with flat HTML backgrounds. |
| Hero tray and tactile rim | Rectangular tray framed by multiple inset brass lines and dark inner rail. `#tray` was authored as a ~258–300 CSS px high stage, with deep shadow / warm-metal rim; large result set inside tray. | **HIGH** for rim treatment/material hierarchy and tactile depth; **DO NOT** copy CSS viewport height. Approved portrait Godot physical scene must remain dominant and strictly overhead, orthographic. |
| Minimal primary action | Centered/near-tray `Бросок`, secondary `Сменить кость`, compositional chips, small amount/modifier steppers, readable state. | **HIGH** for interaction hierarchy, not necessarily exact button shape. Keep seven actually working source dice and current one-dock minimal concept; no fake options. |
| Navigation & progressive disclosure | Top-left hamburger, top-right history shortcut, slide-up `dicePaletteSheet`, `historySheet`, `skinsSheet`, `presetEditor`, non-blocking close/backdrop. | **HIGH**. Rebuild real working Godot mobile sheets with focus/back support, not stock grey modal from current M4. Hide advanced stuff by default. |
| Preset quick bar / editor | Horizontal quick presets, add, named formula, dice/count/modifier, confirm/delete. | **HIGH**. M4 already persists real validated offline presets: improve composition and ergonomics without changing data or needing Supabase. |
| Copyable result | Persistent `Копировать результат` button (disabled until roll), large gold `heroTotal`, formula and breakdown. | **HIGH**. Distinguish individual source faces, modifiers, actual total, and correctly typed D20 crit. |
| Collection | `Скины` bottom sheet tabs: dice, tray, table; options including black obsidian and other appearance profiles. | **MEDIUM**. Approved hidden cosmetics menu can contain only **implemented offline** assets. Do not add fake storefront/buttons or paid API. |
| Sound/vibration switches | User toggles collision sound, vibration, impact vibration. Source `playCollision` and `impactHaptic` reacts to calculated magnitude/pan. | **HIGH**. In Godot drive from **true Jolt contact impulse/location**, implement mute/low motion, honor physical volume/per-device vibration capability. |
| Critical effects | `criticalEffectPlan` supports gold nat20, copper-red nat1, both simultaneously, soft neutral natural high/low, sound/vibration sequences and reduced-motion. CSS uses rings and particles around `#resultCard`; `src/critical-feedback-runtime.mjs` triggers from an `adel:roll-v2` result event. | **HIGH** color/timing/sound references. Godot implementation must instead anchor VFX to the **actual settled D20 die in world space**, only after measured natural result. D&D typed classification: attack nat20 critical hit/nat1 miss; checks/saves are natural extremes, not automatic success/failure; death-save special rules. Non-D20 dice never trigger D20 criticals. |
| Tactile table bounce | Source has `#tray.rollImpact{animation:atelierImpact .14s ease-out}` and `@keyframes atelierImpact{0%,100%{transform:none}38%{transform:translateY(1.5px) scale(.998)}}`; an earlier `rollImpactKick` also moves tray 1.5px. `resultPulse` briefly brightens at end. | **VERY HIGH**. The former impression of a soft impact is from a tiny WHOLE-tray UI transform, **NOT genuine per-contact felt deformation**. For M5, preserve restrained scale (no wobbling camera/rails), but implement local fabric normal/displacement pulse near each Jolt impact, decaying ~150–280 ms with speed/contact-mass response. Rail/Jolt collider remains static. |
| Online spectator broadcast | Alpha 4 can use Supabase guest-read-only 24h live sessions. | **EXCLUDE** from personal, offline-first Godot app. No authorization/login/networking shipped. |

## Critical technical boundary

Alpha 4's design spec explicitly states that **dice result is selected BEFORE visual animation**, using cryptographically unbiased random results and a guided quaternion settling animation to display the chosen value. This is appropriate to that HTML project but is **incompatible** with current approved Godot/Jolt: the only official result is the actual resting physical face (D4 apex), and mathematical signed pool computation must derive from real bodies. **No imported visual code may modify the body pose to force a specific outcome.** Borrow optical language, not outcome-selection or fake physics.

The old Web app also advertises custom dice up to d10000; this is NOT proof of a real 10000-sided physical polyhedron. Godot may show only actually simulated and validated physical dice.

## M5 proposed Gauntlet order (not signed off)

1. **UI artwork/structure**: retain overhead full-sized stage; use aged brass/jade palette, warm typography, structured bottom sheet for real presets/history/die choice; no more floating controls and grey native dialogs. Inspect **real** 720×1280 Godot native PNGs and Android screenshots, not generated concepts alone.
2. **Contact response**: real Jolt `body_entered` / contact impulse → short localized velvet shader ripple/displacement, optional controller/handset haptic and collision-based sound. A no-impact frame must NOT animate. Track exact contact point, amplitude clamped to restrained tiny deformation. Verify 24fps original sequences and never change physics floor collider.
3. **Nat20/nat1**: two separate VFX styles, bronze-gold upward aura and copper-crimson ground pulse, originating at settled true D20; support mixed pools containing both 1 and 20 when truly observed, no false crit for checks/saves; cap intensity for reduced motion. Test cause-and-effect event chronology and original rendered frames.
4. **Material and light**: physically engraved Blender visual-only GLBs, deeper obsidian contrast and readable glyphs in actual Godot Mobile/Mesa; matte black velvet PBR, restrained rail reflections. Compare with Concept 3 and old Alpha 4 source palette. No material changes to Jolt mass/collision.
5. **Independent review**: 3-stage labels `FUNCTIONAL PASS / VISUAL PASS / PHONE NOT VERIFIED`, local Qwen7B only as a source critic, native frame series and AVD original video plus 60fps handset separate. Keep PR #23 draft and M6 separate.

## Source references

- Live deployment: https://adel-dice-roll.vercel.app/
- Source: https://github.com/xxiamadelxx-blip/Dmmaster/tree/8692a682fe34ccc855a0550bf7747eff8846ed29
- Critical effect plan: https://github.com/xxiamadelxx-blip/Dmmaster/blob/8692a682fe34ccc855a0550bf7747eff8846ed29/src/critical-effects.mjs
- Crit runtime: https://github.com/xxiamadelxx-blip/Dmmaster/blob/8692a682fe34ccc855a0550bf7747eff8846ed29/src/critical-feedback-runtime.mjs
- Alpha 4 design: https://github.com/xxiamadelxx-blip/Dmmaster/blob/8692a682fe34ccc855a0550bf7747eff8846ed29/docs/superpowers/specs/2026-08-12-alpha-4-live-design.md
- Approved Dice aesthetic authority: `docs/DESIGN.md`, `docs/VISUAL_ACCEPTANCE.md`.

## 2026-10-12 live browser follow-up: NEW VERIFIED interactive evidence

**Clarification to prior provenance:** The original TinyFish session was blocked by insufficient wallet balance as documented above. A DIFFERENT authorized browser runner, Firecrawl live interaction, **subsequently succeeded** against this same live URL. Treat the earlier 'browser not verified' statement as historically accurate, but superseded for the **specific interactions below**, NOT for animations/audio or phone hardware that were not captured.

- Live browser identified title `Adel Dice Roll α4.0.0`, real visible `БРОСОК` and Web Three status. Pressed **D20 Roll**, waited, and observed a real UI result **17**, including copyable total and breakdown. This is browser UI evidence, NOT proof that Three physics determines outcome (the Alpha 4 source still preselects RNG values).
- Pressed `Сменить кость` and selected **d6** from the working live picker containing d4/d6/d8/d10/d12/d20/d100. Changed count 1→**2** and modifier 0→**+1**; live browser accessibility snapshot updated group chip, caption and footer to **`2d6 +1`** and `2d6 +1 · обычный`. Existing first result remains visible; don't claim it was a 2d6 throw.
- Browser navigation exposed quick presets, D&D roll-type selector, separate advantage/disadvantage segmented buttons, history shortcut and drawer/skin collection. HTML additionally shows dice/tray/table appearance tabs and configuration toggles. Not every button was exhaustively tapped in this run.
- Confirmed served CSS code defines `#tray.rollImpact` and `@keyframes atelierImpact`: at 38% of **0.14 s**, the *whole CSS tray* shifts down **1.5 px** and scales **0.998**; it resets at 100%. The browser automation reported this soft-impact effect associated with the throw; a dedicated 24fps source-frame proof of its exact physical timing is still **NOT VERIFIED**. The user wants this tactile feeling. Our Godot target instead attaches a restrained LOCAL velvet response to real Jolt contact impulse, with static collision geometry and camera.
- Confirmed dedicated `#critFxLayer` and gold/red CSS particles and ring effects, plus live code / UI for nat20/nat1; the **one actual observed D20 throw was 17**, so gold and red critical appearances are **source-grounded but NOT independently triggered/captured in this new session**. Do not label them VISUAL PASS without real nat20/nat1 playback.
- Browser automation describes audio synthesis and `navigator.vibrate` hooks, but it supplied NO audio waveform or real phone accelerometer/vibration evidence. **AUDIO/HAPTICS NOT VERIFIED** by this browser check.
- No spectator live stream created, no paid content purchased, and no privileged site operations performed. No actual video/contact-sheet artifact was exported in this live session; separate 24fps visual acceptance for our **Godot** project remains necessary.

**M5 implications now grounded by interactive checks:** prioritize live-editable pool chips, compact stepper and mode controls, tactile tray/felt reaction, gold/red natural D20 effects, then premium obsidian/velvet styling; preserve our approved hidden advanced controls and strictly overhead camera. Keep HTML preselected outcomes, custom unsupported physical dice and online spectator service OUT of the offline Android runtime.
