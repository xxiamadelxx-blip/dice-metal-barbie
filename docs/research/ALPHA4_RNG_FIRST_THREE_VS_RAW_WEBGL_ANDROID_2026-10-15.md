# Alpha 4 independent Android alternatives to Godot: real code and build evidence

**2026-10-15 · branch `experiment/alpha4-rng-first-webgl` · route `code` + `android-release`**.

## Architecture correction

The user's Alpha 4 behavior is **RNG-first**: securely select 1..20 before starting motion; only then animate a 3D D20 to settle with the already selected numbered face visible. It is NOT dishonest and avoids coupling fairness to physics noise. This experiment must preserve that architecture, not restore the Godot/Jolt source-of-result contract. The Godot/Jolt branch `experiment/m5-learn-codex-d20`, `main`, and draft PR #23 are independent and unchanged.

## First existing proven alternative: Three.js / Android WebView

**Important recovered source**: an earlier THREE.JS browser implementation was already present at `experiments/alpha4-rng-first/main.js`, built with Three.js 0.179.1 and GLTFLoader. It already uses `crypto.getRandomValues` (rejection sampling) and can load the owner's original selected 500k GLB via user file-picker with **SHA-256 verification**. The first real Android debug APK with a simplified, **not original-500k**, demo die has already been built and RUN on an Android 35 x86_64 emulator.

Verified original GitHub Actions **SUCCESS** [#38697870175](https://github.com/xxiamadelxx-blip/dice-metal-barbie/actions/runs/38697870175): Android APK artifact [#11954688414](https://github.com/xxiamadelxx-blip/dice-metal-barbie/actions/runs/38697870175/artifacts/11954688414) and actual Android screenshot/logs [#11955093235](https://github.com/xxiamadelxx-blip/dice-metal-barbie/actions/runs/38697870175/artifacts/11955093235). Actual log:

```text
ALPHA4_WEBGL_QA {"secure":true,"ready":true,"faces":20,"webgl2":true,"noGodot":true,"noJolt":true}
```

Actual emulator screenshot 1080×1920: visible black procedural D20 with bright gold numeral decals, studio interface and **9 FPS on software GPU**. **Not OnePlus Nord3 performance**; original 500k source-PBR GLB was NOT mounted in this screenshot. Existing debug APK SHA256 `8ccd9974623a9017a75c704e3d422d609f016d53a4678e9412aded3b7ea42a5b`.

## Second engine-independent experiment: raw WebGL2 original owner material

Another actual source-only route in `experiments/alpha4-rng-first/alpha4-webgl.html` + `glb-core.js` + `webgl-renderer.js` + `rng-core.js`. **No Three.js, Babylon.js, Godot, Jolt or native 3D engine libraries**. Reads exact original `GLB` 500,000 indexed triangles, 21 mesh nodes, 22 triangle GPU surfaces, seven embedded original PBR PNGs including Blender Cycles 2K baked normal, preserves 20 engraved gold meshes and glTF material factors. The original user-provided exact source GLB SHA256 `60a7d624c126776eb357fb0ba97c8724175a5ec7ce629358276286da75889f39`, private only. Source public, licensed original bytes never committed to GitHub.

For each `Gold_01..Gold_20` actual GLB node, `glb-core.js` reads the node local-Y plane normal and local-Z glyph text up vector, computes a proper quaternion pointing the TRUE engraved number toward the viewer, and rolls the glyph upright. This is superior to using arbitrary icosahedron primitive triangle IDs. Roll animation is a stylized spin/bounce finishing with quaternion SLERP; it is **not a physical rigid-body simulation**. RNG is cryptographic and chosen before frame one.

Actually executed local tests 2026-10-15:
- `node rng-core.test.cjs`: **140,000 rolls**, seven D&D dice sides, rejects 2^32−1 on a forced boundary, no modulo bias.
- `node verify-glb.cjs <private-original-GLB>`: **500,000 true triangles**, all 20 individual gold glyphs and normals, correct on-screen upright orientation for **20/20**.
- `node mock-webgl.test.cjs <private-original-GLB>`: actual binary buffer input through source WebGL2 API simulation: **22 primitive draw calls**, 500,000 input triangles and seven source images, 16,248,416 GPU byte uploads, all boundaries correct.
- **NOT VERIFIED**: real raw WebGL2 original 500k framebuffer on this local Chromium. The Cloud Chromium sandbox disallows WebGL2 even with SwiftShader and refuses localhost and `file://` navigation (`ERR_BLOCKED_BY_ADMINISTRATOR`). Thus these tests are NOT proof of actual GPU visuals or FPS.

### Android WebView source and native install

`experiments/alpha4-rng-first/android-webview/`: minimal native Java Android app shell, Gradle / SDK 35, Java 17; custom HTTPS-origin offline asset interceptor. Unlike the older Three.js APK, this shell **copies the user-picked original GLB once** into app-private storage after streaming exact SHA256 verification, so the user doesn't need to re-select it on each launch. GLB absent/invalid => no substitution; draw disabled. Original source textures stay only on device. Debug APK source and CI in `.github/workflows/alpha4-rng-first-webview-apk.yml`; Android SDK setup v4 was needed (v3 fails due removed `tools` SDK package). Standalone code originally built native APK successfully in [#38708722240](https://github.com/xxiamadelxx-blip/dice-metal-barbie/actions/runs/38708722240) before adding emulator and shader preflight tests; APK SHA256 `7899dd94135e8eed932d472edc364b0981e58a18da9cb101d0b59abe0fcb2b33`, 21,949 bytes, includes Java class in `classes2.dex` and static WebGL source assets. **Not yet Android-emulator visual proof of this new native APK** at the time of writing. Full UI/GPU shader regression now scheduled via Android emulator and saved screenshot.

## Next gates
1. Confirm newest native Android emulator `ALPHA_PLAIN_WEBGL_QA`: secure origin, actual WebGL2 creation, **actual GLSL PBR shader compiled**, not merely packaged HTML. Current CI run #38709342033 queued/in progress as recorded at the latest inspection; do not assert PASS before it completes.
2. Run actual original private 500k GLB GPU draws on Android/OnePlus Nord3; measure FPS, memory, thermal. DO NOT upload original BlenderKit licensed .blend/GLB to PUBLIC GitHub CI.
3. Compare TRUE physically based original obsidian shader on WebGL2/Three.js vs Godot Mobile with matching camera and sampled light, not demo-mesh screenshots.
4. Independent Qwen critic and user art approval still OPEN. Keep Godot feature work intact.
