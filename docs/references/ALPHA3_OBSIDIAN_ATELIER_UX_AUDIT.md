# Alpha 3 Obsidian Atelier: tested UX reference, NOT design replacement

Date: 2026-10-11. Current active product milestone remains **M3**.
User-supplied source: \`AdelDiceRoll_ALPHA_3_OBSIDIAN_ATELIER.html\`, SHA-256 \`69593aca914fdf6725e6a78b3d0adb2304ed4eb532da1a115b441932ef9318e8\`, title \`Alpha 3 · Obsidian Atelier · Three r184\`. **This is Alpha 3, not Alpha 4 or 4.1.** File was supplied in ChatGPT, not checked into this repository (20 MB user-owned reference).
**Authority**: \`docs/DESIGN.md\` and \`docs/VISUAL_ACCEPTANCE.md\` take priority over this exploratory reference. No approved camera angle, physical RNG/face mapping, offline requirement, table/skin aesthetic, or milestone order may be overwritten by this HTML.

## Interactive verification performed

- Loaded original 20 MB HTML into Chromium mobile touch viewport 393x852; also tested 360x800 and 800x393. The test host blocked file navigation, so Playwright \`page.set_content\` was used for the same document. No horizontal scrollbar in responsive checks.
- Executed a sequence of 78 UI steps. 69 completed; 9 were invalid **test harness assumptions**, not confirmed app failures: standard D4/D6/D8/D10/D12/D20/D100 choices close the picker and apply immediately, so a subsequent press on the hidden "Применить" button is incorrect; preset buttons have no \`data-die\` attribute, D8 was selected by index in a targeted follow-up. No JavaScript page errors were detected in successful flows.
- Verified composition \`1d100 + 1d6\`, per-group \`+/-\` count and modifier, advantage/disadvantage controls, expanded advanced toggles, actual fallback throw result and journal entry, clear-history confirm/cancel, saved/reapplied/edited/deleted preset, removal of one group, custom D37 (resulting formula \`1d37 · обычный\`), and drawer/menu/toggle/skin/catalog tab transitions. Switched ru/en/it labels and Crypto/Math/Seed UI options. These are **UI tests** only, not verification of correctness of their underlying randomness.
- Real-screen Xvfb/FFmpeg recordings requested at 24 captured frames/s: navigation 11 seconds (261 source captured frames), roll 8 seconds (187 source captured frames). CFR outputs contain 264 and 192 frames respectively at exactly 24/s, with all original repeats preserved and a few missing captures replaced by duplicates. **19 exhaustive contact sheets of 24 consecutive frames each**, local evidence package \`Dice_Alpha3_UI_Reference_Evidence.zip\` delivered in the conversation; source video names \`navigation_24fps_cfr.mp4\` and \`roll_24fps_cfr.mp4\`. These do NOT prove 24 distinct 3D GPU frames/s.
- \`Three.js@0.184.0\` CDN could not resolve (\`net::ERR_NAME_NOT_RESOLVED\`), so the real HTML/CSS/browser **2D fallback** was tested, not its Three.js WebGL/PBR renderer or genuine physics. DO NOT cite this as successful physical Android/GLB render acceptance.

## Transfer map: preserve behaviors, not old pixel styling

| Reference affordance, verified | Target stage | Implementation principle |
| --- | --- | --- |
| Tiny upper-left hamburger and grouped settings drawer; history shortcut | M5 | Adopt navigation hierarchy; use approved minimalist chrome |
| Dominant stage, close-by roll CTA, formula + result states inside stage | M4/M5 | Live Godot/Jolt table keeps approved orthographic 90-degree overhead, real visible face = outcome; no fake UI-replaced physics |
| Die picker D4/D6/D8/D10/D12/D20/D100, tap a die applies immediately | M4 | Simple selection by default; separate explicit Add To Pool action |
| Editable multi-die pool chips, remove button, active die, count and modifier stepper | M4 | High-priority composition UX; live concise formula and true breakdown |
| Normal / advantage / disadvantage segmented mode | M4 | Enforce approved D20-only advantage mechanics, unlike HTML fallback's broader interactions |
| Collapsed advanced rules to prevent clutter | M4 | Show only implemented validated rules |
| Bottom sheets: die palette, history, collection | M4/M5 | Gesture-friendly sheets with closing/backdrop and restored focus; avoid cluttering live scene |
| Local history, clear confirmation and cancel | M4 | Offline-first persistence, correct D&D total plus raw per-die details |
| Presets: add, name, dice/count/modifier, save/edit/apply/delete | M4 | Offline presets and explicit destructive confirmations |
| Skin library with Dice / Tray / Table tabs | M5 | Separate authored scene assets; reuse existing Blender/MeshLab/ImageMagick/Material Maker/Krita route as appropriate |
| Audio, haptics and settings | M5 | Implement only backed controls; avoid placeholder toggles |
| Store with literal "catalogue not connected" placeholder | NOT MVP | Keep hidden until an actual usable feature exists |
| Small font labels ~7-10 px, very low contrast, large vertical scroll | DO NOT COPY | Raise readability, tap targets >=44 dp where practical, less visible UI above the fold |
| 2D animated PNG/drawn die, predetermined visual outcome | DO NOT COPY | Real physics from Jolt, actual settling face, genuine contact audio/crit aura on **D20 only** |

## Follow-on acceptance boundary

This work is **reference research**, not M3 completion, not an approval of the old Obsidian Atelier visual, and not an authorization to rebuild the approved Concept 3. Do not refactor Godot UI while M3 is incomplete. Feed the behavioral part into M4 acceptance and the navigation/skin hierarchy into M5. Any new M5 art must be constructed through the project-specific creative tool routing and visually compared with the user-approved concept.

For M4/M5 QA: tap every available screen control in real Android, record actual pixels at nominal 24 fps and verify all frames, no misleading false PASS from identical/reassigned die recordings, ensure D100 mode switch is obvious, no placeholder store, no tiny low-contrast button text, and do not label software WebGL fallback as physical Godot/Jolt success.
