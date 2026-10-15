# Android wrapper for standalone WebGL2 GLB Dice experiment

**Experimental, unsigned debug application. NOT a tested Android APK yet.**

Build from this folder with Android SDK API 35, JDK 17 and Gradle 8.12+: `gradle :app:assembleDebug`. Gradle automatically copies the adjacent `../viewer.html` and `../viewer.js` into generated app assets; no network, script CDN, Godot, engine plugin, physics Jolt, or bundled private user licensed GLB. Open app and pick your own `.glb` via Android storage access framework, then tap `Бросить D20`.

- Hardware accelerated Android `WebView` WebGL2, if phone supports it.
- `android.permission.INTERNET` **not requested**.
- JavaScript `crypto.getRandomValues` is mandatory. No `Math.random` fallback.
- Target face chosen before rendering/animation. The original source `Gold_XX` node supplies the per-face direction.
- Only Android-selected `.glb` is loaded in-memory via HTML file input; `file:///android_asset/viewer.html` and its relative JS run offline.
- Android `ACTION_OPEN_DOCUMENT` file picker uses `*/*` fallback for phones that have no MIME registration for GLB.
- On some Android WebView implementations, local `file://` origins restrict `createImageBitmap`, blob loading or WebGL2, and APK field verification is pending. If so, switch to `WebViewAssetLoader` (AndroidX) and HTTPS-like appassets virtual URL in a follow-up build, while keeping offline private material.
- **NOT VERIFIED**: Android compilation, installation, real WebView rendering, OnePlus Nord 3 FPS/thermals. No signing key and no release claim.