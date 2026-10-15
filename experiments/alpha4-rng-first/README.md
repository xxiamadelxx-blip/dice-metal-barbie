# Parallel experiment: Alpha-style RNG-first Android without Godot

**Status: executable standalone HTML/CSS/JS prototype; NOT yet WebGL/Three.js, not an Android APK, not a faithful port of original Alpha 4.**

Open `index.html` in an Android Chromium browser or a WebView. No network, login, external dependencies or engine required. Press **Бросить** to choose an outcome with `crypto.getRandomValues` **before** animating a stylized SVG die. The die is a 2D visual placeholder with CSS 3D rotations. The value shown on completion always equals the preselected RNG result; **this does not yet prove a true 3D mesh will naturally settle with that numbered face upward.**

## Architecture comparison

| Path | RNG authority | Visual engine | Android packaging | Current proof |
|---|---|---|---|---|
| This independent branch | Cryptographic Web Crypto API, unbiased rejection sampling | HTML/CSS/SVG prototype | Future Android WebView/Capacitor wrapper | Browser executable, local Node RNG regression PASS |
| Three.js WebGL 2 | Same | Real PBR GLB, GPU reflections | Android WebView/Capacitor | NOT IMPLEMENTED |
| Babylon.js WebGL 2 | Same | Real PBR GLB, environment prefilter | Android WebView/Capacitor | NOT IMPLEMENTED |
| Unity URP | Same native cryptographic RNG | Unity native graphics | Native Android | NOT IMPLEMENTED |
| Unreal Mobile | Same | Unreal native graphics | Native Android, much larger runtime | NOT IMPLEMENTED |
| Existing Godot/Jolt branch | Jolt top physical face | Godot Mobile Vulkan | Godot Android | Existing project, kept separate |

## Reproducible RNG QA

```bash
node experiments/alpha4-rng-first/rng.test.cjs
```

**Actually run locally 2026-10-15:** PASS 140,000 rolls across D4/D6/D8/D10/D12/D20/D100, all faces observed and within bounds; forced 2^32-1 rejection sample correctly retried before returning a value; invalid sides and unavailable secure RNG throw. Tests prove boundaries and implementation contract, **not** formal statistical certification.

## Next engineering acceptance gates

1. Inspect user-provided original Alpha 4 HTML, recover exact mechanics and camera/UI behavior. Current project context references `AdelDiceRoll_ALPHA_3_OBSIDIAN_ATELIER.html`, not a verified Alpha 4 source file. Do not falsely attribute this prototype to Alpha 4's implementation.
2. Replace placeholder SVG with real WebGL GLB via Babylon.js or Three.js; no proprietary user-selected BlenderKit GLB in public Git.
3. Compute correct orientation of all 20 numbered faces, preselect secure result, animate credible contacts then smoothly finish on correct target face, with no visible snap. Validate 100+ rerolls and face=RNG invariant.
4. A/B render actual identical owner-selected obsidian material under Godot Mobile vs WebGL, match viewport and source, compare legibility and performance.
5. Build real offline Android WebView/Capacitor APK, AVD and physical OnePlus Nord3 GPU/thermal test; no phone proof yet.

This parallel branch must not modify `main`, existing Godot M5 experimental branch or PR #23.
