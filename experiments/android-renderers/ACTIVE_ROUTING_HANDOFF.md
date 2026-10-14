# M5 parallel Android renderer architecture, active checkpoint — 2026-10-15

This is NOT the Godot M5 route; source fork `experiment/m5-android-renderer-alternatives`, do not change `main`, M4 PR23 or previous `experiment/m5-learn-codex-d20`.

## Canonical findings: recovered exact user's Alpha4
Actual private Library `AdelDiceRoll_ALPHA_4_0_0_LIVE(1).html` 16,646,991 bytes: Three.js v0.184.0 WebGL2 (JavaScript/HTML/CSS), PBR MeshPhysicalMaterial, ACES, browser mobile UI. Old Alpha4 pseudo-physics assigns target result BEFORE animating, so must not claim physical outcome-authoritative behavior. First CDN if uncached, unlike our offline bundled APK.

## Tested actual alternative engine work
- Three.js r184/Vite: `experiments/android-renderers/web`; bundled complete ESM no runtime CDN, local GLB and PBR textures picker, SHA256 and 500k/20 gold validation, overhead vs inclined view, actual drawing triangle counter, capture PNG. GitHub native real Chromium WebGL2 synthetic **500k (NO USER MATERIAL, NO GOLD)** achieved 500k GL GPU triangles, one draw, source original PNG #38653824984 PASS.
- Android Java WebViewAssetLoader offline debug APK: `experiments/android-renderers/android`; no Android Internet permission, bundled Three JS. Real 1,348,992-byte app-debug.apk SHA `df96026667f9bb3ebe6a79bf621b12649bdb95951fad2ccbf544dc3b9803152c`, GitHub CI #38654290130 PASS. ACTUAL AVD install/launch/WebGL2 screen pixel PNG/adb logcat #38654987663 PASS (default intro demo 80 tris, NOT owner material). Saved private Library `/Дайс/M5_THREE_ANDROID_WEBGL2_ALTERNATIVE_DEBUG.apk`.
- Native Android **Google Filament 1.57.1** Kotlin `experiments/android-renderers/filament-android`, uses Filament native SurfaceView/ModelViewer + gltfio, local system GLB picker, native PixelCopy PNG, source SHA audit; original 31,169,936-byte APK SHA `9da25036baad361b6afab69bd55cd3e61be0f3c4ae2ea53b9726a41f8b385f02`, real GitHub Gradle Android CI #38655205395 PASS. Saved user Library `/Дайс/M5_FILAMENT_NATIVE_ANDROID_ALTERNATIVE_DEBUG.apk`. Full Android AVD native startup run #38655711764 **started; recheck status**.
- Filament 1.77.3 initially required SDK37, downgraded compatible 1.57.1; actual API differences fixed for Kotlin compilation. Native viewer older version sets its own orbit manipulator on render; fixed-overhead camera parity is NOT VERIFIED, notwithstanding comments.
- Unity URP and Babylon.js remain candidates, not implemented/built; do not imply alternatives were tested.

## Gates not passed
- Critical true original licensed recovered BlenderKit Procedural Obsidian repaired D20 500k GLB SHA `60a7d624c126776eb357fb0ba97c8724175a5ec7ce629358276286da75889f39`, exact true 220k stone + 280k gold, 20 separately engraved numbers, remains **private** Library `/Дайс/D20_500K_PRIVATE_REAL_JOLT_IN_GAME_QA_2026-10-15.zip`. Do not commit original source .blend, PBR PNG, exact GLB, HDR to PUBLIC repository or CI. Both APKs accept user local file chooser; do not claim either actually rendered selected PBR or met art quality yet.
- Same real Android GPU, same PBR source, same camera/exposure/IBL and repeated frame performance not yet measured. Local cloud browser administrator prohibits localhost WebGL2 + crypto.subtle; do not bypass policy or conflate with real public CI working WebGL2.
- Android Filament AVD actual startup and visual source test, actual physical OnePlus Nord3 FPS/thermal, full physics derived outcome (Jolt equivalent) + 1d20+2d6/reroll NOT VERIFIED. Current APKs renderer labs, no final game logic. The user may select their PRIVATE exact original GLB on the phone.
- Independent Qwen visual critic and owner visual approval NOT VERIFIED.

## Next executable actions
1. Check AVD Filament run #38655711764, inspect original logcat/screenshot before confirming native runtime.
2. Test true owner private original D20 on one SAME Android phone in both installers via Android file picker, collect full-resolution original framebuffer PNG from each without giving away licensed art.
3. Correct native Filament orbit vs true camera overhead and use calibrated HDR and physically meaningful IBL in both; compare actual genuine source texture normals / gold engravings (16,17,20).
4. Only if measurable visual+mobile benefit, choose engine and implement honest real physics authority, preserve canonical face mapping, 1d20+2d6/reroll. Do not merge as production while only renderer quality is proven.
