# M5 offline Blender asset proof (D20 + D6)

This tool builds **real 3D stone surface geometry with Boolean digit-contour cuts**, and separate thin metallic 3D digit inlays. It uses Blender and DejaVu Serif installed in GitHub Actions; there are no downloaded textures, external API costs or proprietary source assets.

- Source: `tools/blender/generate_die_assets.py`.
- Cloud build: `.github/workflows/blender-assets.yml`. Its artifact contains two glTF binaries, two actual Blender renders and a face-map manifest.
- Coordinate contract: Godot Y-up vertices -> Blender Z-up -> glTF Y-up. D20 12 collision-aligned base vertices radius 0.88, 20 face IDs and same opposite-pair 1..20 assignment; D6 exact 1.22 unit side and original six labels.
- This is a **staged external visual asset experiment**, not an already approved Godot integration. The existing Jolt collision shapes, RNG, outcome and UI are not touched. First inspect generated GLBs and PNG render evidence, then integrate models as only graphics, verify normals and face index alignment with physical bodies, and rerun all physics and 720x1280 Godot and Android renderer tests.
- The GLBs use standard metallic/roughness Principled materials. Production PBR texture/normal/roughness baking and mobile draw-call/triangle optimization are future hard gates. The proof does not claim true photorealism.
- Artist must reject any visibly distorted glyph cut, collision-bevel mismatch, gapped inset, unreadable number, overdraw or unacceptable phone FPS. PR #23 stays DRAFT and issue #24 stays OPEN.
