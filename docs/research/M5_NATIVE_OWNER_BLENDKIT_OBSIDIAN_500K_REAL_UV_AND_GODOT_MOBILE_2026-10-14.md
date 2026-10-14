# M5: Native original BlenderKit obsidian source on corrected 500,000-triangle D20

**2026-10-14 · creative-3d · isolated experiment branch.** This is an executed private asset bake and real Vulkan Mobile runtime proof, **not** a fictional image, full game release or owner artistic sign-off. `main`, M4 Draft PR #23 and canonical Jolt collider remain untouched.

## Original selected shader: recovered and used, not lost

The exact original **Procedural Obsidian by diaverx miky** (BlenderKit UUID `92e31cbc-5b4e-4ead-a966-84bf106808c3`) was previously acquired and recovered from the user's private Library. Its original Blender `.blend` has SHA256 `3ff237798e8b2498070f886ca43071e43156034358b3694cd7f6c90a63a77cae` and 4,215,232 bytes. Thus anonymous BlenderKit HTTP403 does not imply lack of source. Do not redownload it or replace with a synthetic gray texture. Original node group `Obsidian` contained **14 nodes** and was opened in **actual Blender 4.0.2** offline, using a restored Python3.12/NumPy-compatible open-source runtime.

A complete private, 29-evidence-file package is saved in the authenticated user's personal ChatGPT Library at:

`/Дайс/D20_500K_ORIGINAL_SELECTED_OBSIDIAN_BLENDER_NATIVE_UV_GODOT_MOBILE_PRIVATE_2026-10-14.zip`

Original package SHA256: **`e9a40da06d1c4da173dbf23cbd634aa5b17ea465dd20ccabc402326d96686513`**, size **48,818,661 bytes**. Exact licensed source `.blend`, editable authored scene, final and intermediate GLBs and original shader maps exist *privately in this package*; **do not upload any of these private binaries to public GitHub**. Original source provenance in [restoration receipt](M5_RESTORED_AUTHENTIC_BLENDKIT_OBSIDIAN_PRIVATE_2026-10-14.md).

## Real UV repair, source shader and materials

Source corrected **one D20 500,000 true glTF indexed triangles** `67650874fe979f6b7b82ad0e596fd5ea8d3397c58c50fa0d5cf8e4c83c9edadf`: stone **220,000** (main 51,104 + bevel 168,896), 20 separate gold glyphs **280,000** total. The previous recovered-original-material-transfer GLB `b9f87c663c23b47473261ee11732acd2fa099e37089efeb9e881c532193b5d68` reused the correct original texture bytes **but its 1024x1024 normal and roughness were baked on an old, geometrically different UV atlas**. The error appeared as irregular speckles and excessive mirror response.

The executed repair:
1. Blender 4.0.2 opens **original SHA-verified source `.blend`**, native node group/version-migration reconstructed Principled shader connections and `Obsidian` wave/noise inputs. Full corrected GLB is imported, and **only the main stone facet primitive with valid 0..1 UV atlas** is duplicated as the temporary baking mesh. Numeral gold meshes, original code-assigned face normals and satin bevel surfaces are NOT baked/edited.
2. Actual **Cycles tangent-space NORMAL bake 2048x2048**, 16 samples, 14px margin, on existing repaired facet UV islands. Original source procedural shader (not a painted fake). 51,104 original facet triangles take part. Both actual original-source lookdev variants are preserved:
    - first: wave strength **0.025**, noise **0.0007**, polished stone roughness **0.09**, Blender Cycles PNG + 2K normal map; result GLB SHA `60a7d624c126776eb357fb0ba97c8724175a5ec7ce629358276286da75889f39`, **19,800,336 bytes**;
    - more polished: wave strength **0.008**, noise **0.0002**, stone roughness **0.09**, satin edge roughness **0.22**, glTF normal strength **0.2**; 2K PNG SHA `2dff74de3695287714f0462270489e466abf0bb326dfb853ed9bdb66d7105e60`, final recommended private GLB SHA **`fb315e943aa35cfe2049de457a9effd3d6bc540e38b257496228641c6efedf7a`**, size **18,732,160 bytes**.
3. Private script embeds the new normal map in the original source glTF, sets constant tuned physically plausible roughness rather than sampling old nonmatching roughness atlas, and **asserts exact byte identity of original mesh binary prefix**, equality of glTF meshes, nodes, accessors and **all gold material objects**. Parsing final GLB yields **500,000** real index triangles and **20** unchanged gold glyph objects.
4. Saves the real private Blender 500K full editable `.blend` including the original native material nodes and unmodified gold. Saves original Cycles 900×900 PNGs; the original material is NOT replaced by self-authored gray PBR.

## Actual Godot engine result

Godot **4.6.3.stable.official.7d41c59c4**, actual **Vulkan 1.4.318 Forward Mobile** on **Mesa llvmpipe (LLVM 20.1.2, software GPU)**, native Linux Xvfb:
- Imported and rendered exact **500,000-triangle** original-placeholder, old-PBR-mismatched-UV and newly Cycles-baked original material using one common 1024×896 camera, unchanged gold meshes.
- Three original real engine PNG screenshots and pixel checks (zero image generation), and 5 additional original real HDR yaw 0/35/70/110/150 images. The latter change only HDR panorama orientation, not die geometry or PBR.
- Two Cycles lookdev renders (source wave .025 and polished wave .008), two additional same-HDR-yaw (150-degree) Mobile Vulkan captures comparing true source variants.
- Explicit source runtime console marker `M5_REAL_GODOT_PRIVATE_RENDER ... meshes=21 tris=500000 adapter=llvmpipe (LLVM 20.1.2, 256 bits) renderer=mobile`; engine confirmed native import and image output. Earlier Compatibility/OpenGL fallback is NOT the final Mobile proof.
- User can inspect exact original PNGs in the **private Library ZIP** under `RENDERS/` and all logs under `LOGS/`, with reproducible scripts under `SCRIPTS/`.

## Adversarial quality finding and remaining acceptance

**Baking mismatch corrected, PBR source genuinely restored, real Mobile renderer verified.** However the completely black albedo is original BlenderKit material, so on the current HDR/camera several triangular stone faces become nearly black while other gold numerals are dim. Sky HDR softbox card shapes are visible in the capture background because it is a lookdev sky. This is **not yet the user-approved polished obsidian premium appearance**. The corrected map has subtle normal perturbations by design: not claim strong source bumps if bake is nearly flat. Compare real renders rather than treating darkness or more polygons as a quality score.

Not tested / **NOT_VERIFIED**:
- Android physical OnePlus Nord 3 FPS/thermal limits, final app APK asset integration, Jolt physics and 20-face numeric authority with this particular 500k visual asset.
- Mobile-device visual parity to native Linux llvmpipe, independent Qwen vision critic and owner aesthetic signoff.
- Custom transparent/neutral-background studio presentation and visual contrast improvement on all 20 numeral poses.

**Next concrete step:** improve native Godot lighting/presentation WITHOUT changing restored licensed stone shader, fix background sky cards, test 20 canonical face poses and exact 500k graphic/Jolt coupling, then Android/AVD. Keep original source private and never repeat false 403-blocked-source claims.

**Public repo contains scripts/receipts/engineering records only, no original licensed .blend, maps or PBR-embedded final GLB.**
