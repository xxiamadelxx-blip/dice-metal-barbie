# D&D Dice: tool-selection rules (binding for all agents)

**Scope:** development-time tools only. Product must run entirely offline on Android. **Owner:** agent under Gauntlet Loop. **Status:** routing policy, not proof every program is installed. Check [installation audit](TOOL_INSTALL_AUDIT.md) and latest Actions artifact before launching.

| Tool | When to choose | Entry point / inputs | Output | Pass criteria | Fallback |
|---|---|---|---|---|---|
| **Blender 4.x** | Production sculpt, bevels, actual numeral Boolean engraving, UV, texture bake, glTF | `tools/blender/generate_die_assets.py`, fonts, mesh spec | `.blend` as applicable, `.glb`, PNG preview, manifest | exact dimensions and numbering, real face contour cuts, import into Godot, approved style image review | deterministic Python / existing procedural GLB |
| **Godot 4.6.3 + Jolt** | **Always** for gameplay, tabletop, dice physics, UI, offline storage, VFX, ARM64 APK | `project.godot`, `src/`, `tests/` | playable Godot scenes, native screenshots, APK | true physical outcome/face agreement, all physics tests, visual evidence, Android build, handset gate | never replace runtime without explicit new architecture approval |
| **OpenSCAD** | Parametric proportions, rail dimensions, insert/cut clearance before art | `.scad` numeric constraints | STL/mesh as reference, dimensional manifest | reproducible dimensions, finite mesh, revalidated in Blender | Blender Python mesh scripts |
| **Inkscape** | Vector logo, button icon, decorative filigree, engraving source contours | SVG + approved visual references | SVG/PDF/PNG/vector paths | legible small-size vector art, license and safe import | procedural SVG Python |
| **ImageMagick + Python/Pillow/NumPy** | Resize, crop, packing ORM/roughness/normal RGB channels, contact sheets, masks, pixel critics | image sources from authored tools | deterministic PNGs, JSON metrics | correct colorspace/channel/size and no hidden proprietary asset | Pillow-only or NumPy-only |
| **FFmpeg** | Encode/inspect actual captured Godot frames, assess timing/critical pulse, compress evidence | real PNG frame sequence or recorded test | MP4/WebM/contact clips and metadata | time/frames traceable to engine output, no fabricated video | PNG frame diff + Python |
| **Trimesh** | Mesh programmatic review (watertightness, face count, vertex duplication, normals, export bounds) | GLB/STL/OBJ | QA JSON and optional cleaned reference mesh | geometry constraints stay true; never mutate canonical Jolt hull | Blender validators + glTF JSON |
| **Figma integration** | UI discovery, approved minimalist mobile layout, component consistency | connected authorized design account | reviewable design, screenshot and exported specs | faithful implementation in real Godot Control scene | Godot UI directly, SVG mockup |
| **Canva integration** | Marketing/social visuals and optional 2D artwork, not physics | connected account, own/licensed media | editable ancillary designs / verified PNGs | correct license, export, Android-safe size | Inkscape + Python |
| **Adobe Express integration** | Same limited role as Canva for ancillary 2D design and animation | connected account, own/licensed media | verified exported design | readability and rights | Krita/Inkscape |
| **to3D integration** | Optional reference model from an authorized concept image | connected service + image with reuse rights | candidate 3D mesh | topology/geometry cleaned, numbers checked, full physics decoupling | Blender sculpt |
| **Material Maker** | Reusable procedural PBR graphs only after versioned install and export proof | `.ptex` + Godot-compatible authoring env | albedo/roughness/normal/AO maps | official build checksum, actual executable and CLI export tests; GLB import + pixels | Blender procedural node bake or Python |
| **MeshLab** | Offline scan cleanup / simplification candidates when Blender is insufficient | OBJ/STL/PLY/GLB conversion | repaired mesh + reports | candidate geometry validated, original preserved, face-map agreement | Trimesh / Blender |
| **Krita** | Hand-painted scratches, fabric normals, 2D VFX masks, concept refinement | editable layers and owned imagery | `.kra`, PNG mask/albedo | asset actually exported, visual inspected and rights documented | GIMP / Python / Blender |
| **GIMP** | Retouching, RGBA masks, PBR channel audits and 2D effects | owned raster assets, verified CLI | `.xcf` + PNG | correct color profiles/export and alpha; batch smoke when used in automation | Krita / ImageMagick |

## Mandatory selection procedure
1. Identify source asset, immutable geometry/face constraints, result type, license, delivery deadline and acceptable runtime. Use the **minimum** tools needed. No performative tool usage.
2. Prefer tools verified in this exact environment. The previous table is a routing catalogue, **not** a statement that every application is installed. For GUI/headless capability consult `docs/TOOL_INSTALL_AUDIT.md`, latest CI artifact and binary smoke tests.
3. **Source → intermediate asset → import → native scene → Android:** GLBs and texture maps are noncolliding visual inputs; face values and collision remain in `src/core/` and `src/dice/` under Godot/Jolt.
4. Run import/geometry tests, real 720x1280 native Godot renders, physical tests and Android ARM64 export; inspect pixels/artifact against approved Concept 3. Label any unavailable external account/device gate **NOT VERIFIED**.
5. Independent critic only if actually present. Otherwise use measurable automated critic + honest adversarial visual inspection. On failure modify source at the producing tool, rerun and compare.
6. Paid tools/extra cloud deployments/logins, unlicensed fonts/images and changes to the approved concept require user approval. All optional apps must degrade cleanly to offline, no vendor lock-in or auth loop.

## Usage example: obsidian D20
Blender geometry and UV (canonical physical face mapping) → Material Maker **only if export verified**, otherwise Python/Blender PBR maps → ImageMagick/Pillow channel check → Trimesh and glTF validators → Godot material import and real Mesa frames → Gauntlet screenshot critic → physical Jolt and Android build → Nord 3 final device verification.

## Usage example: HUD and release art
Figma **if connected** or Inkscape SVG prototype → actual Godot Control layout → native 720x1280 screenshots and tap/accessibility review → FFmpeg authentic video of real screen recordings → Canva/Adobe Express **only if authorized** to publish peripheral promotional art. External integrations are NEVER required to compile a game.

## Verified Ubuntu invocation policy (2026-10-10)
See [Xvfb installation CI #38075709599](https://github.com/xxiamadelxx-blip/dice-metal-barbie/actions/runs/38075709599): `gimp --version` can run without X, `xvfb-run -a krita --version` and `xvfb-run -a meshlab -h` returned 0 on Ubuntu 24.04, and the official Material Maker 1.7 archive passed SHA256 and bounded `--version` under Xvfb. `meshlabserver` is present but CLI without display failed, so run a real input/output conversion in Xvfb before processing production models. Material Maker exports `.ptex` via documented CLI but that workflow is still NOT VERIFIED. GUI paint/export workflow for Krita/GIMP similarly unverified. Prefer the established Python/Blender scripts whenever batch headlessness is not proven.
