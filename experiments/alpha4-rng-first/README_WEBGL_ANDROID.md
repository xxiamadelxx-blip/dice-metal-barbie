# Parallel experiment: RNG-first original-obsidian D20 without Godot

Independent branch `experiment/alpha4-rng-first-webgl` of `xxiamadelxx-blip/dice-metal-barbie`.

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