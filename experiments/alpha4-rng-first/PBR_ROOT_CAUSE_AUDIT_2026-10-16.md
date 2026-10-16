# PBR source-material forensic audit (Alpha4 RNG-first WebGL2 experiment)

Date: 2026-10-16. Branch: `experiment/alpha4-rng-first-webgl`.
Scope: **same exact owner-selected private 500,000-triangle GLB**, same browser, camera, gold 20 face and resolution in an A/B experiment. Godot `main` and PR #23 unchanged.

## Primary-source finding, independently read from binary GLB JSON

Owner GLB SHA-256 `60a7d624c126776eb357fb0ba97c8724175a5ec7ce629358276286da75889f39` (19,800,336 bytes). Exact material node `GoldRecessedNoEmission` contains
`pbrMetallicRoughness.baseColorFactor=[0.560000002,0.335000008,0.104999997,1]` and `roughnessFactor=0.349999994` with **no `metallicFactor` property**. Per normative glTF 2.0 PBR defaults, unspecified `metallicFactor=1.0`; old WebGL source incorrectly used `pbr.metallicFactor ?? 0`, making gold dielectric instead of metallic. Furthermore, the old shader used hard-coded `uGoldBase=.56,.335,.105` instead of the GLB color factor. The GLB stone normal map explicitly says `normalTexture.scale=0.2`; the old shader hardcoded this, and other materials would have been incorrectly interpreted.

**Corrective commit:** `3af0c9af6e8b799de0c00cee59e883b672e81c6b` in `viewer.js`: default metallic=1, normal scale from source (default 1), source base color factor passed to GPU and multiplied with texture sample; eliminates fixed gold color. Source-only regression `tools/pbr_material_contract.test.cjs` commit `af9df4dfae263595d41ba9c7a09a8944da339287`, installed as a mandatory Android build gate in `.github/workflows/alpha4-webgl2-android-debug.yml` commit `9c14d786315fdd9cc619b22b96ac04a9a0579b63`.

## Actual WebGL2 A/B: outcome

Launched **real headed Chromium ANGLE SwiftShader WebGL2** using Xvfb, original private GLB loaded by the real browser file input. Both variants rendered all 500,000 triangles / 22 draw surfaces with GL error **0**; gold source face **20**, UI selected **20**, rotated actual original gold face normal dot forward = **0.9999999999999998**. Same 720×720 canvas, static camera/pose. The saved before PNG SHA256 is `9885d25996dc8bc53d5a6bf74469b839f11cae6a4cc0a9dea327e421319a7559`; after PNG SHA256 `5baf8e97ae28047f32e5cf0c673afd965917ed9cd94916d84fba8f35ca0da881`.

**Critical art finding:** A/B difference is **small**: only **1.413% of pixels change** at all, 1.012% change by ≥10 channel levels; mean absolute RGB difference per canvas pixel is **(0.174, 0.135, 0.081)** of 255. The corrected gold is slightly darker; the underlying black surface and pale specular facet remain artistically unchanged. **Thus fixing glTF metallic/default parameters does NOT resolve poor source obsidian art**, and should not be promoted as a visual PASS.

Before/after images and `pbr_qa.json` are saved in the private user conversation `/mnt/data/alpha4_deep_2026_10_16`, not the publicly licensed source repo. Public script test is source-only; private original GLB never uploaded to GitHub/CI.

## Differential diagnosis for next loop

Existing fragment shader samples source albedo and normal maps, but uses **three hand-coded reflection disks** based on the reflection direction and scalar fresnel. It does not evaluate equivalent real environment maps/prefiltered specular IBL like Godot or Blender; gold KHR_materials_clearcoat extension is not represented in fragment. This is a verified implementation limitation, not proof of what visual quality is attainable on WebGL2. Next investigation should hold the exact real light environment and color management matched before comparing engines; do not compare scene brightness at different camera scales.

**Android evidence separately**: prior real Android 15 emulator CI `38749780238` (synthetic 40 triangle GLB), real WebGL2 GPU screenshot, face11=UI11, GL error0. Original private GLB 500k in Android WebView and device FPS/thermal remains **NOT VERIFIED**. Current new-commit Android CI must be consulted live; do not assume success from push.

**Gauntlet**: real A/B, direct source material evidence and runnable static regression: PASS within scope. Independent external critic Qwen: **NOT VERIFIED**; human artistic acceptance: **OPEN**; exact original Alpha 4 HTML: **NOT RECOVERED**.

Use this for handoff, not promotional equivalence claims.
