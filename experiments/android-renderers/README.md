# M5 renderer bake-off: native Android outside Godot

**Branch:** `experiment/m5-android-renderer-alternatives`, forked from `experiment/m5-learn-codex-d20` on 2026-10-15. This is NOT a production switch or an approved M5 art pass. **Never modify main or M4 PR #23** via this experiment.

## Verified Alpha 4.0 Live tech stack

Original user-owned personal Library: `AdelDiceRoll_ALPHA_4_0_0_LIVE(1).html` (16,646,991 bytes), actual title `Adel Dice Roll · Alpha 4.0.0 Live · Obsidian Studio`. It is a standalone mobile-first **HTML + CSS + JavaScript** application running a **Three.js r184 WebGL2** 3D scene via `new THREE.WebGLRenderer`, PBR `MeshPhysicalMaterial`, ACES tone mapping and browser DOM interface. Its loader uses jsDelivr `three@0.184.0` if localStorage caching is empty, which means standalone cold start depends on Internet (localStorage cache cannot be treated as an app asset). That is a blocker to an offline APK; bundle the exact JS module in Android app assets.

**Approved parallel-branch experiment:** Alpha 4 selects a target with Web Crypto rejection sampling, then animates the 3D die to match it via pseudo-physics / quaternion interpolation (`d.result=d.target`, `faceToViewer`). This is a legitimate RNG-first virtual dice roller, and the user has explicitly chosen it for this alternative engine experiment. We do NOT change production Godot/Jolt semantics without a separate design decision. Random result must be unbiased, finalized before visual motion and visually correct.

This file is **user-owned Library content, not committed to public GitHub**. Reuse its styling/interaction intentionally only after auditing embedded secrets, third-party analytics, license requirements and code; the study references it directly instead of copying an unreviewed 16MB inline file into the repo.

## Experimental choices and order

| Track | App packaging | Renderer | Physics in full product | Priority |
|---|---|---|---|---|
| **Web Three.js r184** | Android Java WebViewAssetLoader + offline bundled Three.js | WebGL2, ACES, glTF PBR, PMREM studio | **WebCrypto RNG-first**, cinematic 3D tumble to fixed result, independent final visible-face assertion. No Jolt required. | **1, implemented** |
| **Native Filament** | Native Android Kotlin APK, Filament gltfio-android | physically based IBL/HDR, Vulkan/OpenGL ES | RNG-first animated face target can be implemented natively; AVD startup currently failing, not production-ready | **2** |
| Babylon.js | Android WebView / Capacitor | PBR WebGL2 / conditional WebGPU | RNG-first animated target, same quality gate as Three.js | 3, not built |
| Unity URP | Unity-produced APK | URP PBR / baked area, mobile reflection probes | independently selected RNG outcome then cinematic target-face animation | 4, not built |
| Current Godot Mobile | existing APK | current Godot Mobile PBR | existing Jolt/top-face baseline, untouched by parallel experiment | Baseline |

**Pass/fail comparison must hold constant**: same verified single 500,000 indexed-triangle source GLB (220k engraved obsidian + 280k 20 gold glyphs), original recovered **BlenderKit Procedural Obsidian** map bytes, same approved overhead camera, same effective framebuffer resolution, comparable lighting and tone mapping. Record original **actual** GPU screenshots and same-phone measured FPS, memory and temperatures. For this RNG-first branch, validate unbiased precommitted outcomes and exact final visible gold parity for all 20 values, advantage/disadvantage and compound sums; Jolt-authoritative settle is NOT a requirement.

## Private-source boundary

Real licensed source original BlenderKit `.blend`, baked 2K maps and integrated verified premium master `d20_selected_original_500k.glb` **do not go into public GitHub**. Source master SHA-256 `60a7d624c126776eb357fb0ba97c8724175a5ec7ce629358276286da75889f39`. Retrieve user-private bundle from personal Library `/Дайс/D20_500K_PRIVATE_REAL_JOLT_IN_GAME_QA_2026-10-15.zip`. Web tester accepts chosen GLB via local file picker and explicitly reports SHA and triangle count; source is never uploaded to a server by the code. Native APK can separately package asset in a **private** build once redistribution/packaging permission is validated, not in a public CI build.

## First working increment

`web/` now contains an **actual RNG-first Three.js mobile dice prototype**: draws unbiased D20 outcome using secure WebCrypto before animation, animates all 20 possible final face orientations, verifies the final geometric top number, supports disadvantage/advantage and numerical 1D20+2D6. Only D20 is visually animated in mixed rolls. It additionally imports the real user-owned 500K GLB privately by file picker, preserves PBR material maps, and measures real WebGL2 triangles, CPU timing and captures PNG. This is not yet the complete Alpha4 user interface. A synthetic model generator is used only to validate the public CI renderer pipeline, prominently marked **not the owner's material/model**, with exactly 500k distinct triangles but no golden numbers. The physically authoritative dice engine / art parity and native mobile QA come after this baseline.

Android Java wrapper `android/` contains an offline WebViewAssetLoader shell. It is a proper installable APK after the Three source is bundled and copied to `android/app/src/main/assets/`. It does not request user account/authentication, camera or Internet to work.

## Acceptance gates

1. **WEB_ENGINE_RUNS:** actual Chromium WebGL2 software GPU on CI renders loaded **synthetic** 500k-triangle GLB with screenshot, native context, camera, correct counter; no fake screenshot.
2. **ANDROID_APK_INSTALLS:** Android Gradle debug APK built and installed on an Android emulator/device; loaded offline index+Three scripts, file picker and GLB working. CI compilation alone is not device testing.
3. **PRIVATE_MATERIAL_VISUAL_PARITY:** actual original licensed 500k GLB with the original maps on the same mobile GPU, contrast/digits comparable to Godot.
4. **RNG_FIRST_ROLL_AUTHORITY:** WebCrypto rejection-sampled precommitted result, no modulo bias; cinematic Three.js quaternion animation settles matching real visible gold 1..20, opposite=21, advantage/disadvantage and mixed RNG math. Jolt-independent by deliberate design.
5. **M5_ART:** actual owner's review + independent critique; no acceptance by polygon count alone.

**Latest verified**: [Chrome/WebGL2 + RNG-first 5/5 tests + 500K synthetic GLB + rebuilt offline Android APK #38657853529](https://github.com/xxiamadelxx-blip/dice-metal-barbie/actions/runs/38657853529) PASS. Real original owner PBR 500K and actual new APK emulator AVD still require independent verification. **M5 final status OPEN.**
