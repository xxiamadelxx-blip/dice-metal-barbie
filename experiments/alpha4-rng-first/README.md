# Independent Alpha-style D20: Three.js WebGL2 + secure RNG + native Android WebView

**State (15 October 2026): Working real 3D browser prototype and offline Android debug APK + actual Android 15 emulator boot.** This is a separate experiment, not approved final art or a replacement for existing Godot M5.

## Original references

The actual personal Library file `AdelDiceRoll_ALPHA_3_OBSIDIAN_ATELIER.html` (20 MB, 2511 source lines) was recovered and inspected: **Three.js r184**, source-authored PBR atlas, 3D geometry, UI/history and RNG modes including cryptographically sampled rejection sampling. This confirms the earlier Alpha 3 prototype already used Three.js and RNG-first presentation. **Alpha 4 exact source has NOT been recovered**, so never claim this copy is a byte-faithful Alpha 4 port. Keep that UI as a reference for later.

## Actual implementation (separate from Godot)

- `main.js`: authentic Three.js **WebGL2** scene of twenty separately numbered triangle faces, clearcoat dark stone, separate canvas-backed gold labels, true source vertex normals. Orthographic approved top-down camera. No Godot, Jolt or physical outcome authority.
- `rng.cjs`: secure Web Crypto `getRandomValues`, 32-bit unbiased rejection-sampling. RNG value **committed BEFORE** 3D rotation, die quaternion interpolated toward the selected actual face normal. Final face normal measured on the actual WebGL mesh, not asserted by API alone.
- `index.html`, `bundle.js`: locally bundled with esbuild; `alpha4_rng_first_webgl_standalone.html` is an independent **fully offline HTML**, no CDN.
- **Optional source user-selected private original**: `main.js` includes a GLTFLoader file-picker gated on exact SHA256 `60a7d624c126776eb357fb0ba97c8724175a5ec7ce629358276286da75889f39`, checks **500000 indexed triangles / 20 gold objects**, then uses real imported gold object orientation for each RNG-target face. No original BlenderKit source or glTF maps are committed to PUBLIC Git. **Actual user-selected 500k input path test in Three/WebView remains NOT_VERIFIED**, despite code building successfully and corrupt GLB SHA-fail-closed browser test passing.
- Native Android project `android/` uses Gradle AGP 8.8.2 / Android API35 / Java17 / AndroidX WebViewAssetLoader. `https://appassets.androidplatform.net/assets/exp/index.html` is a secure local origin, no INTERNET permission, full bundled Three.js and WebCrypto. Native `ACTION_OPEN_DOCUMENT` file picker can select user-owned GLB without storage permissions or cloud. Debug only, not signed release.

## Real test evidence

- [Browser renderer 20/20 real 3D upper faces and RNG-first original Chromium pixels, CI #38696008659](https://github.com/xxiamadelxx-blip/dice-metal-barbie/actions/runs/38696008659) **SUCCESS**. Browser test runner `qa.browser.mjs` verified all twenty target values -> actual upward normal dot >0.9999 and (visible label = RNG). Real original screenshot stored in `evidence/real_threejs_canvas_d20_20.png` on experiment branch.
- [Real Android WebView APK and Android 15 emulator #38696775783](https://github.com/xxiamadelxx-blip/dice-metal-barbie/actions/runs/38696775783) **SUCCESS**. App actually installed; native log `secure:true, ready:true, faces:20, webgl2:true, noGodot:true, noJolt:true`. Android emulator original screenshot stored in CI artifact. Emulator initial software GPU only about **6 FPS** at original high resolution with 1024 shadow map; not phone FPS.
- Iteration removed heavyweight dynamic shadow and capped mobile framebuffer pixel ratio to 1.25, added proper Android API35 status-bar insets, and real input acceptance regression. Post-change emulator and real tap proof require checking the latest CI outcome before claiming improvement.
- `rng.test.cjs` executed via Node CI: **140,000** random values on D4/6/8/10/12/20/100, all within bounds/all labels appeared, rejection boundary and missing secure RNG fail safely. Not a formal uniformity certification.
- Client-side `qa.browser.mjs` also rejects a deliberately invalid user GLB before altering the model or previously generated result.

## Run

```bash
cd experiments/alpha4-rng-first
npm install
npm run build
node rng.test.cjs
# Serve files from a secure http://localhost origin, or directly open:
# alpha4_rng_first_webgl_standalone.html
```

For Android: `gradle -p android :app:assembleDebug` after copying `index.html`, `bundle.js`, `manifest.webmanifest` into `android/app/src/main/assets/exp/`; automated CI handles this and Android emulator install. **No physical OnePlus Nord 3 benchmarks**.

## Next decisive experiment

Use original private 500K BlenderKit D20 in the **same** Android WebGL stage, verify 20 original engraved gold labels and 500000 actual indices, then measure shader compile, memory and 20 mobile RNG-target animations. Compare matched frames to existing Godot Mobile reference under equivalent pose/HDR, and test both APKs on OnePlus Nord3. The public demo uses a deliberately simpler die until private GLB import is actually executed and proven.

Original Godot M5 branch, `main`, M4 PR #23 unchanged. No approved product decisions have been revised outside this independent experiment.
