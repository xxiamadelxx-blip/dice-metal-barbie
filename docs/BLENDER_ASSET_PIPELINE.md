# M5 offline Blender asset proof (D20 + D6)

This tool builds **real 3D stone surface geometry with Boolean digit-contour cuts**, and separate thin metallic 3D digit inlays. It uses Blender and DejaVu Serif installed in GitHub Actions; there are no downloaded textures, external API costs or proprietary source assets.

- Source: `tools/blender/generate_die_assets.py`.
- Cloud build: `.github/workflows/blender-assets.yml`. Its artifact contains two glTF binaries, two actual Blender renders and a face-map manifest.
- Coordinate contract: Godot Y-up vertices -> Blender Z-up -> glTF Y-up. D20 12 collision-aligned base vertices radius 0.88, 20 face IDs and same opposite-pair 1..20 assignment; D6 exact 1.22 unit side and original six labels.
- This is a **staged external visual asset experiment**, not an already approved Godot integration. The existing Jolt collision shapes, RNG, outcome and UI are not touched. First inspect generated GLBs and PNG render evidence, then integrate models as only graphics, verify normals and face index alignment with physical bodies, and rerun all physics and 720x1280 Godot and Android renderer tests.
- The GLBs use standard metallic/roughness Principled materials. Production PBR texture/normal/roughness baking and mobile draw-call/triangle optimization are future hard gates. The proof does not claim true photorealism.
- Artist must reject any visibly distorted glyph cut, collision-bevel mismatch, gapped inset, unreadable number, overdraw or unacceptable phone FPS. PR #23 stays DRAFT and issue #24 stays OPEN.

## Verified headless Gauntlet export and visual inspection (2026-10-10)

- [Blender production-art prototype CI #38068337940](https://github.com/xxiamadelxx-blip/dice-metal-barbie/actions/runs/38068337940) **PASS**: exact D20 face numbering (20 numbered faces; 2594 shell polygons) and D6 (6 numbered faces; 665 shell polygons), two real exported GLB binaries and two Cycles screenshot renders. Subsequent [gold visibility iteration #38068580919](https://github.com/xxiamadelxx-blip/dice-metal-barbie/actions/runs/38068580919) **PASS**.
- First procedural proof failed because 20 successive Boolean operations erased D20 at face 2; now all vector font cutters are joined and subtracted through one exact Boolean operation. D6 coincident vertices were welded before modeling.
- The Ubuntu Blender 4.0 runtime required explicit `python3-numpy` and disabled OpenImageDenoise to render headlessly. Both requirements are now codified in CI.
- `tools/blender/validate_glb.py` validates actual GLB headers and glTF mesh/accessor geometry, exported shell bounds, exact ordered face-number map, separate stone/gold materials and real PNG evidence, with no new host packages.
- **Art gate STILL OPEN:** snapshot renders show gold inlay more readable, but we have no in-engine Godot integration, no comparison with the original approved Concept 3 under Android Mobile renderer, no mobile FPS result or production PBR baked normal/roughness maps. Do not merge PR #23 or close issue #24 based only on Blender screenshots.

## Gauntlet material pass: embedded procedural PBR textures (2026-10-10)
- Blender now generates deterministic 256x256 low-contrast obsidian **albedo, roughness and tangent-space normal PNGs** from periodic multi-frequency smooth noise, creates stone spherical UVs after the exact Boolean cut, connects the image nodes to Principled BSDF, and exports them in GLB. This is **offline procedural map generation, NOT a high-poly-to-low-poly Cycles normal bake**. Do not describe it as that.
- `validate_glb.py` requires PNG sources, embedded GLB image/texture objects, `TEXCOORD_0` on the cut stone mesh, and material references to all three texture channels. `tests/engraved_assets.gd` then verifies that the running Godot scene applies the imported texture channels via a controlled lit material override. A green Blender generator alone is not acceptable unless the native scene imports the refreshed GLBs.
- Approved sculpt geometry, original Jolt collision, numeric face IDs, body mass and critical aura logic remain unchanged. Texture seams, visibility and Android GPU are still visual/phone acceptance gates. The Blender workflow compares binaries and only pushes regenerated GLBs to the **approved draft feature branch** if the validated bytes differ; `main` stays untouched.
