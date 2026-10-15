# M5 independent native WebGL2 owner-selected obsidian 500K, RNG-first Android experiment

**2026-10-15. Experimental branch only** `experiment/alpha4-rng-first-webgl`. Godot main, original Jolt and PR #23 were not changed. This experiment uses the original owner-selected licensed BlenderKit Procedural Obsidian by diaverx miky, source GLB SHA256 `60a7d624c126776eb357fb0ba97c8724175a5ec7ce629358276286da75889f39`, 19,800,336 bytes **only in private local test**. No private BlenderKit GLB/maps committed into public GitHub or Android APK.

## Actual breakthrough

Previous local software-browser attempt failed because headless Chromium / disallowed file and localhost navigation could not create a WebGL2 context. Resolved by **real headed Chromium 144 on virtual Xvfb display with ANGLE SwiftShader software OpenGL driver**. Browser content populated through Playwright `page.set_content` (not `page.goto` blocked local URL). No fake GPU image or Blender substitute.

Built and committed the independent dependency-free `experiments/alpha4-rng-first/viewer.html` + `viewer.js`. The real WebGL2 shader/importer loaded the original 19.8MB private source GLB **1.3 seconds in one real desktop run** (not a hardware Android FPS or loading benchmark), correctly imported original embedded source PBR albedo/normal PNGs, and uploaded **500,000 indexed triangles: 220K stone (two graphic primitive surfaces) + 280K twenty gold digit meshes = 22 GPU drawing surfaces and 20 unique gold labels**. Original source GLB bytes remained unchanged.

The built-in Web Crypto API chooses uniformly unbiased D20 result with 32-bit rejection sampling **before** animation. A full 20/20 face orientation loop completed: source gold face directed toward camera has normalized dot > .999999 and **matches displayed result** for all 20. Real Chromium WebGL framebuffer PNG files exist for source gold 1/11/20. Two real random browser animation outcomes (13 and 16) settled correctly, and 16 after latest texture change: **RNG=16, UI=16, real gold front=16**, GL_ERROR=0, browser page exceptions=0.

Side by side private screenshot of **same original GLB** Godot and WebGL2 exists, but the composition, camera scale, and lighting differed. DO NOT claim WebGL superior GPU/PBR until controlled normalized A/B lighting/size and original phone hardware measurements.

## Android 15 debug app

Source `experiments/alpha4-rng-first/android-app` compiles a native Android WebView application with local `file:///android_asset/viewer.html` + bundled offline JS, hardware acceleration, system SAF file-picker for user-owned private `.glb`, **no INTERNET permission**. GitHub Actions [#38719678088](https://github.com/xxiamadelxx-blip/dice-metal-barbie/actions/runs/38719678088) completed **SUCCESS**. Built Android debug APK SHA256 `a159a3c6f803b3bcda69bca45f99f91af4909e5fc1540e04c32c5ed378d9cfc2`, 17,851 bytes, contains HTML/JS Java dex and manifest, no proprietary glTF/.blend. This tiny size is feasible because WebView is supplied by the Android OS, not bundled.

**Actual Android 15 Google APIs x86_64 emulator boot + adb install + native launch passed**. Real Java `WebView.evaluateJavascript` verified `window.DiceExperimentalQA`, real canvas `getContext('webgl2')`, and Crypto RNG, yielding log `ALPHA_WEBGL_LAB_QA true`. Original actual Android emulator screenshot and log saved in [CI artifact](https://github.com/xxiamadelxx-blip/dice-metal-barbie/actions/runs/38719678088). It shows the offline app before selecting GLB.

**NOT VERIFIED**: importing original private 500K GLB directly into Android WebView and measuring real fps/per-frame allocation/thermal; real physical OnePlus Nord 3; full 24fps film/physics-natural animation artistic signoff. Current animation is scripted smooth targeting, not true Jolt bounce physics. APK is **unsigned for production** (standard debug signed via Android tooling), not Play Store release.

## Provenance and artifacts

Persistent private owner Library: `/Дайс/AdelDice_ALPHA_RNG_First_500K_TrueWebGL2_Source_Android_QA_2026-10-15.zip`, SHA256 `a1594b0791d2d5ccdac7d663a85de272f9724e9f6695509028baec7b72583ce8`, with runnable viewer source, Android sources, genuine Chromium photos, reproducible 20-face QA JSON and side-by-side proof (NO licensed GLB). File is also available as this conversation's generated ZIP. Original Android emulator proof downloaded from CI run #38719678088.

Existing parallel Three.js r184 implementation in same experiment was previously verified on Android emulator with an offline APK. It is not known whether the **exact Alpha 4** source is available; the recovered Alpha 3 HTML uses Three.js. Continue comparing Godot, Three.js and custom WebGL2 without rewriting the original Godot branch, and retain RNG-first as game outcome authority for this alternate prototype.

**Next meaningful test:** private GLB imported to Android app via file chooser, verify the true engraved number in original pixels, measure Android hardware or emulator 500K fps and memory, improve final cinematic material and bounce appearance via 24fps QA.
