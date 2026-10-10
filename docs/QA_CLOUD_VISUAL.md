# Cloud visual acceptance · actual evidence, not mockups

**State 2026-10-10:**
- PASS: APK v0.0.6 ARM64 successfully installs and launches inside Android 15 Pixel 6 x86_64 emulator with `libndk_translation.so`. Android screenshots are blocked by the emulator GPU (black frames).
- BLOCKED: Godot 4.6.3 Mobile/Vulkan using SwiftShader: present failure; separate Compatibility/OpenGL APK also black. Exact log: `SceneShaderGLES3: Program linking failed: Fragment shader active uniforms exceed GL_MAX_FRAGMENT_UNIFORM_VECTORS (261)`; reduced OpenGL lights did not resolve it. Upstream godotengine/godot#109550. Latest host GPU alternative is experimental, not accepted until it produces nonblank screens.
- PASS: **real running Godot scene** (not APK) rendered under Linux Mesa OpenGL / Xvfb in Actions run 38057180593. Screenshots `native-01-launch.png`, `native-02-moving.png`, `native-03-after.png` show actual D6 movement and top-face numeral, separate result. This is useful visual QA but **not proof of Android rendering or phone performance**.
- PASS for initial UI overlap fix in merged [PR #21](https://github.com/xxiamadelxx-blip/dice-metal-barbie/pull/21): [actual corrected frames](https://github.com/xxiamadelxx-blip/dice-metal-barbie/actions/runs/38057685664) show table and opaque bottom dock no longer overlapping, readable controls, cleaned-up heading and UI result matching physical D6 face. All headless physics/rules and ARM64 debug export also green in [run 38058147915](https://github.com/xxiamadelxx-blip/dice-metal-barbie/actions/runs/38058147915).
- STILL OPEN (Issue #20): small/dark die, obsidian material realism and physically rotated numeral legibility. These need further visual iterations and real Android screenshot evidence.

## Workflows
`.github/workflows/godot-native-visual.yml` runs per relevant scene/UI PR and manually. It runs Godot's real renderer under Mesa and captures 3 images, rejects empty or unchanged output. An independent critical review of screenshots must then compare against approved art direction and log defects.

`.github/workflows/android-visual-qa.yml` remains **manual only** while emulator backend is defective. Builds QA-only OpenGL variant, installs into Android emulator, performs ADB interactions, captures four PNG screenshots and logcat, and fails on blank/unchanged pixels. It must **not** mark Android as PASS merely because installation and the process are alive. Normal Mobile/Vulkan release APK is not changed by this workflow.

## When evaluating images
- Verify camera exactly overhead, no black-screen or system overlays; visible rail/table, dice numbering and face orientation.
- Ensure control dock and table don't interfere, and status/copy state match the scene.
- Only real-frame references, never AI-generated mockups, prove implementation quality.
- Mark Android handset, haptics and sounds NOT VERIFIED unless actually tested with that hardware or a suitable emulator/sensor setup.
- Every FAIL belongs in GitHub issue with run ID, screenshot, reproduction and next corrective commit. Gauntlet Loop until acceptance.
