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

**Status as authored:** Source implemented, waiting CI results; do NOT claim working Android RNG-first APK until actual updated build and AVD passed.
