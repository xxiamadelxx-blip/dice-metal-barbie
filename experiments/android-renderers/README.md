# M5 renderer bake-off: native Android outside Godot

**Branch:** `experiment/m5-android-renderer-alternatives`, forked from `experiment/m5-learn-codex-d20` on 2026-10-15. This is NOT a production switch or an approved M5 art pass. **Never modify main or M4 PR #23** via this experiment.

## Verified Alpha 4.0 Live tech stack

Original user-owned personal Library: `AdelDiceRoll_ALPHA_4_0_0_LIVE(1).html` (16,646,991 bytes), actual title `Adel Dice Roll · Alpha 4.0.0 Live · Obsidian Studio`. It is a standalone mobile-first **HTML + CSS + JavaScript** application running a **Three.js r184 WebGL2** 3D scene via `new THREE.WebGLRenderer`, PBR `MeshPhysicalMaterial`, ACES tone mapping and browser DOM interface. Its loader uses jsDelivr `three@0.184.0` if localStorage caching is empty, which means standalone cold start depends on Internet (localStorage cache cannot be treated as an app asset). That is a blocker to an offline APK; bundle the exact JS module in Android app assets.

**Critical physics distinction:** Alpha 4 selects a target with Web Crypto rejection sampling, then uses hand-coded JavaScript kinematic pseudo-physics / quaternion interpolation, including `d.result=d.target` and `faceToViewer(d,bf)`; actual collision is NOT the authoritative returned result. Our production Dice Roller uses Jolt top-face physics; never silently replace honest physical roll with predetermined Alpha 4 logic.

This file is **user-owned Library content, not committed to public GitHub**. Reuse its styling/interaction intentionally only after auditing embedded secrets, third-party analytics, license requirements and code; the study references it directly instead of copying an unreviewed 16MB inline file into the repo.

## Experimental choices and order

| Track | App packaging | Renderer | Physics in full product | Priority |
|---|---|---|---|---|
| **Web Three.js r184** | Android Java WebViewAssetLoader + Vite bundled Three, offline APK | WebGL 2, ACES, physical glTF PBR, PMREM sky | Separate **real** physics (Rapier WASM or another independently verified engine) after rendering QA. Never Alpha 4 scripted `d.target` | **1** |
| **Native Filament** | Native Android Kotlin/Java APK, Filament gltfio-android | physically based IBL/HDR, Vulkan/OpenGL ES | Jolt native binding or other physically observed Android engine with face/number parity | **2** |
| Babylon.js | Android WebView / Capacitor | PBR WebGL2 / conditional WebGPU | verified external physics (Rapier/Havok) | 3 |
| Unity URP | Unity-produced APK | URP PBR / baked area, mobile reflection probes | Unity Rigidbody collisions, independent face authority | 4 |
| Current Godot Mobile | existing APK | current Godot Mobile PBR | current tested Jolt, canonical baseline | Baseline |

**Pass/fail comparison must hold constant**: same verified single 500,000 indexed-triangle source GLB (220k engraved obsidian + 280k 20 gold glyphs), original recovered **BlenderKit Procedural Obsidian** map bytes, same approved overhead camera, same effective framebuffer resolution, matching lights/HDR/tonemapping as closely as possible. Record original side-by-side **actual** GPU screenshot, 60-second cold/steady frame FPS on a **real phone**, GPU/CPU/JS heap when measured, memory, app size, physical settle 1..20 and triplet formula/reroll parity. No ranking based on desktop llvmpipe vs Android GPU.

## Private-source boundary

Real licensed source original BlenderKit `.blend`, baked 2K maps and integrated verified premium master `d20_selected_original_500k.glb` **do not go into public GitHub**. Source master SHA-256 `60a7d624c126776eb357fb0ba97c8724175a5ec7ce629358276286da75889f39`. Retrieve user-private bundle from personal Library `/Дайс/D20_500K_PRIVATE_REAL_JOLT_IN_GAME_QA_2026-10-15.zip`. Web tester accepts chosen GLB via local file picker and explicitly reports SHA and triangle count; source is never uploaded to a server by the code. Native APK can separately package asset in a **private** build once redistribution/packaging permission is validated, not in a public CI build.

## First working increment

`web/` is a minimal **renderer-only** comparative tool, NOT a complete Dice Roller: import real GLB by file picker, preserve glTF material channels, view strict top-down with controlled studio IBL, see actual GPU triangle draw count, check WebGL2, performance, and save actual screenshot. A synthetic model generator is used only to validate the public CI renderer pipeline, prominently marked **not the owner's material/model**, with exactly 500k distinct triangles but no golden numbers. The physically authoritative dice engine / art parity and native mobile QA come after this baseline.

Android Java wrapper `android/` contains an offline WebViewAssetLoader shell. It is a proper installable APK after the Three source is bundled and copied to `android/app/src/main/assets/`. It does not request user account/authentication, camera or Internet to work.

## Acceptance gates

1. **WEB_ENGINE_RUNS:** actual Chromium WebGL2 software GPU on CI renders loaded **synthetic** 500k-triangle GLB with screenshot, native context, camera, correct counter; no fake screenshot.
2. **ANDROID_APK_INSTALLS:** Android Gradle debug APK built and installed on an Android emulator/device; loaded offline index+Three scripts, file picker and GLB working. CI compilation alone is not device testing.
3. **PRIVATE_MATERIAL_VISUAL_PARITY:** actual original licensed 500k GLB with the original maps on the same mobile GPU, contrast/digits comparable to Godot.
4. **REAL_ROLL_AUTHORITY:** physics-derived face matches visible gold, 20 faces, opposite=21 and 1d20+2d6/reroll scenarios. No predetermined outcomes.
5. **M5_ART:** actual owner's review + independent critique; no acceptance by polygon count alone.

**M5 final status remains OPEN until all applicable gates are proven.**
