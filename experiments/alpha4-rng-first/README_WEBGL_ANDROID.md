# Parallel experiment: RNG-first original-obsidian D20 without Godot

Independent branch `experiment/alpha4-rng-first-webgl` of `xxiamadelxx-blip/dice-metal-barbie`.

## Latest real checks · 15 October 2026

- **REAL Android 15/API35 WebView with public synthetic 40-triangle D20: PASS.** Latest [GitHub Actions run #38749780238](https://github.com/xxiamadelxx-blip/dice-metal-barbie/actions/runs/38749780238) built an installable offline APK and installed/started it in Pixel 6 AVD using Android WebView WebGL2, checked source QA: `ready=true, face=11, front=11, triangles=40, parts=21, bright=7794, glError=0`. [Actual 1080×2400 screen and Android log](https://github.com/xxiamadelxx-blip/dice-metal-barbie/actions/runs/38749780238/artifacts/11979169727). The screenshot is of **synthetic geometry with golden triangular markers**, never call this the real owner source.
- **The production-size, owner-selected 500K BlenderKit D20 is verified in REAL Chromium WebGL2, not Android.** Actual current rerun loaded private GLB with SHA `60a7d624c126776eb357fb0ba97c8724175a5ec7ce629358276286da75889f39`, 500,000 triangles / 22 surfaces / 20 real golden digit meshes, and secure RNG 18 = UI18 = printed front18 with WebGL errors 0. Forced `createImageBitmap` failure also loaded 500K original GLB via `HTMLImageElement` fallback, with face11 and GL error0.
- **Android SAF picker now has no MIME filter**, because `.glb` often has unknown MIME. [Source fix](https://github.com/xxiamadelxx-blip/dice-metal-barbie/commit/308bf110ac754095643713c47061693086668d43); latest APK tested in CI [artifact](https://github.com/xxiamadelxx-blip/dice-metal-barbie/actions/runs/38749780238/artifacts/11980841419), SHA256 `e8731eee3a7904f193af1a505fc45819f3165b6ebdcdb1daebb071f6e53b7c15`, 21,158 bytes. No private GLB is inside this public/debug APK. Synthetic fixture is visibly labelled [source commit](https://github.com/xxiamadelxx-blip/dice-metal-barbie/commit/7e1cc613e6e0e46d0b2f1b9403646073cf1904ac).
- **NOT VERIFIED:** exact selected private 500K model from Android SAF in actual AVD/phone, Android real GPU/frame times with 500K original material, real OnePlus Nord 3 performance, perfect physical landing, matching Godot look, user artistic approval. No Qwen independent critic run. Original Godot branch, main, draft PR#23 untouched.



## What actually exists (2026-10-15)

- **One original source 500,000-triangle D20 GLB** loaded from a private file, SHA-256 `60a7d624c126776eb357fb0ba97c8724175a5ec7ce629358276286da75889f39`.
- Dependency-free WebGL2 implementation parses 21 mesh nodes / 22 draw surfaces, seven embedded images (original BlenderKit baked 2K normal, obsidian albedo, other source maps), 20 separate gold digit meshes, and original glTF PBR material constants.
- Numbers are drawn from `crypto.getRandomValues()` with **unbiased rejection sampling before animation begins**; a quaternion targets the normal of the actual `Gold_XX` GLB node and separately rotates the glyph upright. Unlike the old Jolt-first engine, the animation never generates a random outcome.
- The bounce / spin / final interpolation is a visual simulation, NOT actual 3D contact physics. No false claim of natural physical settles.
- WebGL2 shaders: textured stone PBR approximation with analytic GGX, Fresnel reflection and one soft circular light; no godot/three/babylon dependency. **This is a prototype shader, not yet matched to Blender Cycles, and no physical WebGL GPU screenshot has passed**.
- Android Studio WebView app source `android-webview/`: offline local virtual HTTPS asset origin; custom file picker imports verified original GLB once into internal storage. It does not bundle user-licensed source artwork in the public Git repository.

## Private end-user test on Android Chromium

1. Unpack the **private experiment ZIP** on an Android device (do not use the source-only ZIP if you want the original D20 ready to select).
2. Open `alpha4-webgl.html` in Chromium if the browser allows local file access. Tap **Оригинальный D20 GLB** and select `d20_selected_original_500k.glb` from the same ZIP after extraction.
3. Tap `Бросить D20`. The RNG number is chosen before the animation and the original GLB is oriented accordingly. No server, login, API key or online provider.
4. If WebGL2 cannot initialise, the page displays an error; it **does not silently replace** a 3D proof with a static picture.
5. For an actual Android native app, build/install the APK from `android-webview/` or use the CI-produced debug APK. The APK itself does not contain the licensed GLB: tap file select once, let Android verify and store the exact bytes, and future launches load the stored model automatically.

## Reproducible tests (run locally)

```
node rng-core.test.cjs
node verify-glb.cjs /private/path/d20_selected_original_500k.glb
node mock-webgl.test.cjs /private/path/d20_selected_original_500k.glb
```

Recorded results on 2026-10-15:

- **PASS** 140,000 RNG rolls, range and all-face coverage on D4/D6/D8/D10/D12/D20/D100, forced rejection of 2^32-1 sample.
- **PASS** real original GLB 500,000 triangles, 21 nodes, exactly 20 separate gold glyphs; 20/20 numeral normals and upright quaternion poses verified.
- **PASS** WebGL2 API-shape mock for original source: **22 triangle draw calls, 500,000 triangles, 7 image byte blobs, 16,248,416 bytes of GPU buffer upload**.
- **NOT VERIFIED** real Chromium/WebGL2 native GPU framebuffer in this workspace. The Chromium sandbox returns `webgl2=null` despite SwiftShader args, and blocks `file://` or `http://127.0.0.1` via `ERR_BLOCKED_BY_ADMINISTRATOR`; mock tests do not prove actual GPU performance or image quality.
- **NOT VERIFIED** Android Gradle APK build / emulator / physical OnePlus Nord 3 until CI confirms. Never call prepared Java source a built/installable APK prematurely.
- **NOT VERIFIED** exact user Alpha 4 (original HTML from previous thread is Alpha 3 filename and has not been inspected in this turn); architecture mirrors user-confirmed RNG-first strategy but is NOT a verbatim port of Alpha 4.

## What not to change

Original selected BlenderKit source material must remain in private user materials, not public Git. Do not merge into `main`, PR #23 or replace approved Godot/Jolt source. This is an independent renderer comparison. Never conflate 500k single-mesh-bundle rendered triangles with GPU-instanced 50 million benchmark. All original gold faces are real GLB nodes, not SVG text painted above geometry.