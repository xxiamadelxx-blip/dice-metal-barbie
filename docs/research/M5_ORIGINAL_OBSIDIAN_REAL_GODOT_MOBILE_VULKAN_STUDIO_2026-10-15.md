# M5 real recovered original obsidian: Godot 4.6.3 Mobile/Vulkan polished studio proof

Date: 2026-10-15 (local). Isolated `experiment/m5-learn-codex-d20`. **Real output, not generated images**. M5 overall ARTISTIC and ANDROID acceptance **OPEN**.

## Previous blockers actually addressed
- The actual `Procedural Obsidian` chosen by the user (BlenderKit / diaverx miky / UUID `92e31cbc-5b4e-4ead-a966-84bf106808c3`) WAS recovered and is present in the user PRIVATE Library, not lost / not inaccessible. Recovered source sha256 `3ff237798e8b2498070f886ca43071e43156034358b3694cd7f6c90a63a77cae`. Do not retry unauthenticated blocked web requests.
- Genuine source shader has already been RE-BAKED in **Blender Cycles** into a new UV-specific **2048px tangent normal** for the repaired 500K master. Exact final source-PBR GLB SHA256 `60a7d624c126776eb357fb0ba97c8724175a5ec7ce629358276286da75889f39`, 19,800,336 bytes.
- Exact Godot GLB index audit **500,000 single-mesh-bundle triangles**: 220,000 engraved stone / 280,000 original separately rendered gold letters, 20 gold meshes, 21 imported meshes. **Not** 50M submitted instanced-triangle experiment.
- Old local capture logged Godot 4.6.3 **Compatibility/OpenGL** renderer, and drew white light card polygons into the camera image, which was misleadingly compared to Blender Cycles. These were NOT source-material failures.
- Recovered actual **Godot 4.6.3.stable.official.7d41c59c4 Vulkan Forward Mobile** executable from CI artefact run #38627152931; recovered native software **Mesa lavapipe Vulkan ICD 1.4.318** from #38629472843. Ran native Godot Mobile locally from a private temporary project under Xvfb; all source GLB imports succeeded.
- Original Blender Z-up panorama HDR `studio.hdr` sha256 `a816625569d497e3672d522357c8ae292b9ef947eb3ae1c80c00e33f76b6a971` needed a longitude remap to Godot Y-up: `U_Blender = (0.25 - U_Godot) modulo 1`; remapped HDR sha256 `c163961799e16e4c86976189e00e62985ca16ca9327f1ac0af6f8c33c876a506`. Original HDR RGBE pixels only REORDERED, not painted, no modified stone material.
- Correct `Environment.REFLECTION_SOURCE_SKY` with a separate dark **background_color** avoids visually exposing giant white HDR panels. Native 0°, 60°, 120°, 180° yaw tests captured real frame results (different physical angles of specular reflection).
- Test bench `tools/visual/owner_selected_m5_500k_mobile_capture.gd` was executed locally in an isolated private Godot `res://` project with original private source GLB/HDR placed under `res://assets/`. It is public source ONLY, never bundling a proprietary material.
- Actual visibly improved candidate **`probe_refined`**: five physical emissive studio reflectors rendered on a hidden camera layer, captured by real Godot `ReflectionProbe` and rendered only as reflections on the polished stone. The two new panels target approximately the actual reflected view vectors of face 20 and 17; after wide-card tests washed the top face grey, these two were reduced to 48% angular width and 80% intensity. Gold material receives a LOCAL RUNTIME per-mesh material duplicate with albedo `(.92,.64,.27)`, metallic `.55`, roughness `.29`, clearcoat `.08`. The actual GLB and all 500K vertex positions/face mapping/20 glyph objects remain byte-identical to original recovered GLB. The selected obsidian's base albedo/normal/roughness maps stay **unmodified**. No painted highlights, no material replacement with synthetic black.
- Actual 1000×850 Godot Mobile screenshot visual test: die #20 top face shows a narrow dark-blue controlled studio sheen rather than flat 100% black or gray-filled face; #16 visible original source rough micro-bump; #17/18 gold legible. The staged old GL Compat screenshot previously had camera-visible white studio panels.
- Native renderer log source: `Vulkan 1.4.318 - Forward Mobile - Using Device #0: Unknown - llvmpipe (LLVM 20.1.2, 256 bits)`, the real command `godot --display-driver x11 --path . --rendering-method mobile --audio-driver Dummy --script res://capture.gd -- --variant=probe_refined --yaw=0`, and `M5_REAL_GODOT_SOURCE_CAPTURE ... mesh_count=21 stone_tris=220000 gold_tris=280000 gold_count=20 ...`. Renderer shutdown emitted `7 RIDs of type Texture were leaked` warning after successful PNG output: track for actual game acceptance, not a render failure.

## Private recovery / downloadable assets

All **source licensed assets** and native output preserved in the private user Library:

`/Дайс/D20_500K_OWNER_SELECTED_BLENDKIT_REFINED_GODOT_MOBILE_PRIVATE_QA.zip` (38,691,311 bytes compressed; SHA256 `bb8005464c4cb10a2ea03eae987c9467aa561792881fad35cdb87b45b3029aa8`). Contains private original BlenderKit `.blend`, edited Blender master `.blend`, 2K source-normal PNG, exact rebuilt GLB, original & aligned studio HDRs, locally executed Godot project and GDScript, real Blender and Godot screenshots, 4-way original comparison PNG, logs and SHA manifest. DO NOT upload this to public GitHub or put `*.blend` / `*.glb` / `*.hdr` / source map bytes in a public branch.

Comparison real source PNG in Library:

`/Дайс/M5_REAL_BLENDER_GODOT_MOBILE_500K_RECOVERED_OBSIDIAN_4WAY.png`

Actual camera crop PNG:

`/Дайс/M5_ACTUAL_GODOT_MOBILE_500K_GOLD_20_16_17_CLOSEUP.png`

Both are user-review attachments, rendered from actual engines (not generated mockups). Their first Blender image and old Compatibility Godot differ in camera/renderer; do **not** treat their pixel differences as matched camera quality scores. **Two latest Mobile renders (baseline and refined) use identical camera+geometry**, but differ in actual light cards and runtime gold presentation.

## Remaining work / safety rails

- **NOT_VERIFIED**: the source material visual fidelity is not identical to Blender Cycles; a reflective facet moves correctly under studio rotation but several other facet faces still appear dark because specular reflection depends on pose and physical normal. Owner must still approve visual style; do not claim finished obsidian/gold.
- **NOT_VERIFIED**: this is a separately captured D20 in native Godot **Mobile Vulkan on desktop CPU llvmpipe**. It is NOT an app APK, Android AVD or physical OnePlus Nord 3 GPU FPS/performance proof. Real gameplay render, actual physics Jolt, canonical face outcome, Android thermals and device frame timings remain untested on the 500k + source material integration.
- **NOT_VERIFIED**: independent local Qwen vision critic. Do not pretend a successful visual critic reviewed these images.
- Do not merge or modify `main`, do not disrupt M4 Draft PR #23.
