# Alpha4-style RNG-first: independent WebGL2 native Android model-render proof

**2026-10-15 · Branch:** `experiment/alpha4-rng-first-webgl` · Not a product M5 acceptance or exact original Alpha4 implementation.

## What genuinely ran

**Desktop original-owner D20:** Private original BlenderKit-selected 500,000-triangle GLB, SHA256 `60a7d624c126776eb357fb0ba97c8724175a5ec7ce629358276286da75889f39`, loaded **locally** into actual headed Chromium 144 ANGLE/SwiftShader WebGL2. Actual 20 separate numbered gold meshes were rendered at all 20 target orientations, each correct target gold face matched UI, and WebGL error 0 throughout. Three real browser-secure RNG clicks yielded **17,20,17**, each selected number = gold front-facing face = UI. Original 20-face contact sheet and browser JSON privately archived; SHA of original native contact PNG `9deed3ad596cec8866679c40035078fc670b461098a02e4191c5e5419246758c`. Proprietary GLB is **not** in public GitHub, CI, screenshots ZIP or public Android APK.

**Real Android 15 API35 Pixel6 AVD WebView:** On [GitHub Actions #38730514459](https://github.com/xxiamadelxx-blip/dice-metal-barbie/actions/runs/38730514459) **both APK-build and actual emulator jobs PASS**. The fully offline native WebView app installed and started. Debug-only `qa_fixture` intent loaded a **new, fully unlicensed synthetic** 6,504-byte glTF 2.0 D20 fixture (1 body + 20 separate Gold_N nodes; 21 parts, 40 triangles) via **the real original GLB parser** and sent draw calls through the real in-app WebGL2 GPU context. This fixture uses flat golden triangular markers rather than source-owner engraved numbers on purpose. Native Android log:

```text
ALPHA_WEBGL_LAB_QA true
ALPHA_ANDROID_MODEL_QA {"ready":true,"face":11,"front":11,"triangles":40,"parts":21,"bright":7794,"glError":0}
PASS_REAL_ANDROID_WEBVIEW_GLTF_20_FACES_GPU_PIXELS
```

The screenshot is **original AVD screen capture**, 1080×2400. It shows genuine simulated black D20, golden triangular markers and UI **11**, without the launcher overlay. Screenshot SHA256 `2bdcfdb002326aef8e5f0aaa27b3167ca454032fe57e328c13f6334101170fcb`; complete AVD before/after + native log archive SHA256 `4476ac8125952df4596094eae0c0a40a21eae46a9fa10d09b513c1d0495d5db5`, GitHub [artifact #11970865040](https://github.com/xxiamadelxx-blip/dice-metal-barbie/actions/runs/38730514459/artifacts/11970865040), persistent user Library `/Дайс/ALPHA4_REAL_ANDROID_WEBGL2_GLTF_GPU_SCREEN_LOGS_2026-10-15.zip` and PNG same folder. Browser source/test JSON/code archive `/Дайс/alpha4_rng_first_true_glb_android_qa_2026-10-15.zip`.

First emulator capture on [earlier run #38729777142](https://github.com/xxiamadelxx-blip/dice-metal-barbie/actions/runs/38729777142) proved genuine 7794 GPU pixels but had `Pixel Launcher isn't responding` system ANR dialog over the screenshot; retest #38730514459 captures clean frame. **Do not assume this removes all emulated-device stability risk.** Source generator at `experiments/alpha4-rng-first/tools/make_public_qa_glb.py`, Android debug-only injection in `android-app` MainActivity, assertion parser `tools/check_android_gpu_qa.py`. The CI fails if any other GLB/BLEND is packaged or if GPU pixels are missing. No Android Internet permission.

## Not verified and next action

- **Owner private original 500K GLB in Android WebView itself NOT VERIFIED.** The GLB document picker is implemented but must receive actual owner file, render all 20 real engraved gold digits and measure RAM/FPS/thermal; Android current proof uses only synthetic 40 triangles.
- **No physical OnePlus Nord 3 test** or UI motion/frame-by-frame Android QA. Real native WebGL2 texture and glTF semantics on actual phone remain to check. WebGL2 custom shader uses a PBR approximation; true owner premium obsidian appearance needs image comparison under matching camera/HDR/viewport with Godot; owner signoff not claimed.
- Target result is selected with secure RNG before roll animation, and quaternion orients real source glyph to viewer on desktop. Animated believable collisions/settling without visible forced snap are not proven by static source-face checks.
- Existing Godot `main`, PR #23 and independent Godot M5 source branch untouched. No proprietary material committed. Independent Qwen critic NOT VERIFIED.
