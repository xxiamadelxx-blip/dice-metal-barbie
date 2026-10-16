# Original private BlenderKit 500k D20: SHA-256, quaternion/root-cause and actual WebGL2 screenshot QA

**Date:** 2026-10-16. **Branch:** `experiment/alpha4-rng-first-webgl`. **Artifact:** private Library `/Дайс/alpha4_rngfirst_500k_original_sha_quat_visual_qa_2026-10-16.zip` SHA256 `c9c679ce34bccef7987fe2b6ef1c7a496d16574ee2c7b56cc71dc273a68a0e11`. No licensed GLB is included in the artifact or public GitHub.

## True source and engineering facts

- Owner-selected BlenderKit D20 source GLB **19,800,336 bytes**, SHA256 `60a7d624c126776eb357fb0ba97c8724175a5ec7ce629358276286da75889f39` private at `/mnt/data/dice_m5_work/project/assets/d20_selected_original_500k.glb`.
- Real Chromium 144 / ANGLE SwiftShader software WebGL2: **500,000 indexed source triangles, 22 original surfaces, 20 engraved gold source digit meshes, GL error 0**.
- **PASS SHA positive/negative:** 19.8MB true original validated BEFORE GPU upload, one-byte corrupted same-sized GLB rejected with `ready=false`, `triangles=0` and SHA mismatch error. `crypto.subtle` unavailable in `about:blank` insecure browser context; pure JS SHA256 fallback independently compared to Node's crypto official vectors and full owner GLB (596ms Node local). Real browser passed both SHA branches.
- **Root cause in shipped viewer.js:** quaternion multiplication's Z component used `a3*b2+a0*b3+a1*b0-a2*b1` instead of Hamilton `a3*b2+a0*b1-a1*b0+a2*b3`. Composing roll spins with face target could rotate wrong numbered face to front. Fixed source. Independent algebra property `rotate(qMul(A,B),v)=rotate(A,rotate(B,v))` now checked.
- **Actual source glyph sign root cause:** Gold mesh authored in local XZ plane, visually upright direction **local -Z** (not +Z); private source gold node has its own rotation. Source quaternion target now aligns the actual chosen number normal to camera AND rotates authored gold glyph to readable screen-up. Separate synthetic QA triangle uses local +Y. Earlier trial positive-Z orientation visibly rendered 20 as inverted `02`, corrected after original Chromium PNG comparison.
- **PASS real original 20/20 face/gold upright geometric tests:** top dot >=0.999999, lateral up X~0, upright screen Y >=0.999. Real Chrome screenshot shows genuine source golden **20** properly upright; actual RNG-first throw selected face **8**, golden 8 and UI 8, GL error 0. Tested source/strict SHA negative and source screenshot+timing logs in persistent private ZIP above.
- **FAIL 24 FPS in DESKTOP CPU Software GL:** 1,750ms animation yielded approx 4 sample intervals, mean 516.75ms, worst 850ms, three intervals >42ms. This is evidence of inefficient SwiftShader software rendering, **not evidence of failure or success of mobile phone GPU**. No claim of natural physical-looking animation after independent visual frame inspection.
- **Android app:** last verified CI Android15 synthetic 40-triangle GPU fixture rendered and matched label, but **owner original 500k inside Android still NOT VERIFIED**. New SHA+quaternion source is in branch and workflow `.github/workflows/alpha4-webgl2-android-debug.yml` now enforces regression in real Android build; inspect latest Actions before acceptance.
- Independent external Qwen critic NOT VERIFIED. Controlled matched-resolution/lighting Godot vs WebGL2 original asset render NOT VERIFIED. Exact original Alpha 4 source NOT VERIFIED. Do not alter main or Godot M5 PR23.

## Next check

Use private original 19.8MB GLB through Android system picker in latest regenerated offline APK, capture actual phone/emulator original source pixels, verify SHA and label, record 24fps + GPU timings. Keep fixture QA distinguished. Use original Blender source + matching HDR and FOV for subsequent controlled Godot vs WebGL2 diagnostic, not the existing unmatched glamour screenshots.

## Reproducibility

Independent contract test: `node experiments/alpha4-rng-first/tools/check_sha_quaternion_upright.cjs [PRIVATE_GLB_PATH --private]`. Public synthetic 20-face fixture used by CI in `android-app/app/src/main/assets/qa_fixture.glb`, and the real source private file used in owner-only check. Native HTML full-size screenshots and measurement logs permanently in the private QA archive with checksum above. No model source bytes published.
