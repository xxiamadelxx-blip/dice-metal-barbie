# Independent Android/Three.js Alpha 4 RNG-first experiment

**2026-10-15. Isolated branch `experiment/m5-android-renderer-alternatives`.** Production `main`, old Godot M5 source and M4 PR #23 unchanged.

## User-approved outcome semantics (explicit correction)

The source-owned **Alpha 4.0 Live HTML is a Three.js r184 WebGL2 app** with Web Crypto unbiased RNG selecting `d.target` **before** presentation physics, then a cinematic quasi-physical animation bringing the die to that predetermined numbered face. Its physical collisions do NOT determine the DnD result. This is a **valid and appropriate choice** for a visual Android dice roller. Our previous claim that Alpha 4 was wrong because it did not use Jolt-authoritative face outcomes was a design error and must not be repeated.

**For this new ALTERNATIVE branch the acceptance contract is**:

1. Native browser/WebView secure `crypto.getRandomValues` with rejection sampling selects uniform individual die outcomes. **No `Math.random` fallback**. Generate chosen result before first animation frame and store it immutable.
2. Three.js performs pseudo-physical tumbling, damping, bouncing and a smooth final quaternion alignment to the **already chosen** face. No re-rolling or changing the preselected result after animation.
3. Independently evaluate the geometrically upper face from the final quaternion in JS. Require visible gold == preselected RNG target for all 20 D20 face values; fail if mismatch, never silently substitute.
4. For advantage/disadvantage, securely roll two d20 values and choose max/min before visualization; for `1d20+2d6`, securely roll three independent dice and sum, but current prototype animates only the D20. Do **not** claim the two D6 physically animate.
5. Offline installed Android WebView + bundled Three 0.184.0, no CDN or requested Internet permission. Original user BlenderKit material and unique 500K/20 engraved gold GLB stays private, never committed to public repo. For default quick smoke the app displays a **clearly identified synthetic numbered D20 demo**, not the proprietary real obsidian.
6. If user chooses authentic private GLB with SHA256 `60a7d624c126776eb357fb0ba97c8724175a5ec7ce629358276286da75889f39`, 500000 true triangles, stone220000/gold280000/20 gold meshes, apply the tested rigid rotation to canonical face vectors. Do **not** offer guaranteed-number animation for an unverified GLB whose printed faces may differ.

## Implemented technical source

- `experiments/android-renderers/web/src/rng_first.mjs`: crypto 32-bit rejection sampling, actual 20-facet face normals+engraved gold mapping, D20/advantage/disadvantage/mixed RNG; no Three/Godot dependency for outcome.
- `experiments/android-renderers/web/src/dice_animation.js`: synthetic clearly labeled numbered D20 only for offline demo; quaternion target from original 20-gold mapping, random spin, simulated bounce and convergence; **in final frame independently measures top face**.
- `experiments/android-renderers/web/src/main.js`: in-app RNG-first buttons+status, immutable preselected result per roll, 50-entry history, verified private 500K original art loading as before; arbitrary unrelated GLB remains viewable but cannot claim correct RNG->engraved-face mapping.
- `experiments/android-renderers/web/tests/rng_first.test.mjs`: real Node tests of RNG rejection, all face-antipodes and 20 target quaternions, deterministic scripted animation, advantage/compound math.
- `experiments/android-renderers/web/tests/smoke.mjs`: actual Chromium/WebGL2 smoke: visually numbered real Three D20 follows chosen RNG result; tests `1d20+2d6` sum and preselected visible target, original browser PNG, then loads publicly generated synthetic 500K (no owner art) and asserts GPU submits actual triangles with real pixels.
- Original `.github/workflows/m5-alternative-three-webgl-android.yml` now gates APK compilation on passing RNG Node tests plus Chromium real GPU screenshot. Same `Android WebViewAssetLoader` APK build as separate Godot-free variant.

## Important boundary

This is not a deterministic rigid-body physical simulation or a Jolt stand-in. Its physics-like movement is *cinematic*. Target result is random and independent of the animated collisions by design. Full 3D multi-die animations, art parity and frame performance on physical OnePlus Nord 3, Android cold-start, UI acceptability and independently evaluated output remain separate tests.

Google Filament native renderer is an **additional independent track** but its recent CI AVD runs **#38655711764 and #38655979139 FAILED** with native Activity not active/emulator startup trouble; Filament successful APK compilation does **not** mean working Android GPU. Babylon.js/Unity URP not executed. Three.js Android AVD previously worked (#38654987663) but older APK was a renderer-only app. Need new updated APK AVD screenshot to mark actual RNG-first Android UI as running.

## Evidence

New actual CI (update after run): [workflow history](https://github.com/xxiamadelxx-blip/dice-metal-barbie/actions/workflows/m5-alternative-three-webgl-android.yml).

**Verified current state:** all required browser and Android **RNG-first execution** checks passed (see directly below). User's original BlenderKit GLB / on-device Nord3 visual parity and D6 multi-body presentation remain open. This is an Android-usable experimental APK, not a released final Dice Roller.

## Real regression proof, 2026-10-15

- [Actual GitHub Chrome WebGL2 + offline Android APK build #38657853529](https://github.com/xxiamadelxx-blip/dice-metal-barbie/actions/runs/38657853529) **PASS**. `npm test` 5/5 including all 20 unique canonical D20 face values, dice opposites21, crypto rejection, 1d20+2d6 sum, all target-quaternion poses and end-of-animation geometrical face parity. Real Chromium GPU screenshot shows Web Crypto selects **19**, gold top after animation **19**; mixed independent RNG `9+3+6=18`, D20 visibly lands **9**. Synthetic unlicensed 500000-triangle GLB actual Chrome GPU draw **500000 triangles in 1 draw call**. Not selected private obsidian art proof.
- **Installable offline Android APK** built from same source: 1,352,224 bytes SHA256 `bf16fb6b76ee9034a303fdc06e4b7a935a70e27e6446dd7fb54f7c11f367a5fe`, package `com.adeldice.threelab`, targetSdk35/minSdk26, bundling complete Three.js v0.184.0 and CSS/HTML. **No Internet permission or third-party CDN** at runtime. Original debug APK preserved in CI run artifacts and user conversation.
- [Real Pixel 6 Android 15 emulator clean launcher screenshot #38658823402](https://github.com/xxiamadelxx-blip/dice-metal-barbie/actions/runs/38658823402) **PASS**, true 1080×2400 screen original Android screenshot and WebGL2 app. Previous screenshot #38658376155 was falsely accepted with system **Pixel Launcher isn't responding** overlay; AVD smoke regression now rejects accessibility-reported launcher ANR and no longer uses obstructed frame as visual proof.
- [Actual Android WebView RNG-first tapped D20 #38659245462](https://github.com/xxiamadelxx-blip/dice-metal-barbie/actions/runs/38659245462) **PASS**: Android uiautomator found real `Бросить D20` DOM accessibility bounds (296, 2325), `adb shell input tap` caused real WebCrypto RNG-first animation, and the resulting native Android screen/accessibility dump independently confirmed **RNG11 = visually displayed D20 gold11 = UI total11**, not inferred from a mocked JS callback. Screenshot is `REAL_ANDROID_RNG_FIRST_D20_AFTER_ROLL.png`; original PNG and exact JSON preserved in GitHub artifact **#11938606144**. No Pixel Launcher ANR overlay in final screenshot.
- Emulator uses software graphics and at last capture showed ~5 fps. This is not real OnePlus Nord 3 GPU FPS and is not fit for hardware comparison. The main native Filament prototype has not yet completed runtime PASS; two initial native JNI library loading crashes were separately diagnosed.

## Future actual same-source quality comparison

1. Run the *exact* private user BlenderKit source `d20_selected_original_500k.glb` SHA `60a7d624c126776eb357fb0ba97c8724175a5ec7ce629358276286da75889f39` via installed app's Android document picker in a private session. Keep original bytes out of public git/CI. Confirm all 20 printed gold, original 2K normal and gloss under approved overhead camera.
2. Compare against Godot and native Filament on the **same actual Android GPU** with same original GLB, viewport, light/HDR and exposure, true device frame cadence and memory/thermal profile. Do not claim superiority from synthetic or desktop software graphics.
3. Expand animated 3D dice to all D6 and double D20 for advantage/disadvantage (RNG correctness implemented, but only one chosen D20 is visually animated today), rethrow rules and finished Alpha4 UX.

