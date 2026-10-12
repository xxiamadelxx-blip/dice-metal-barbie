# Isolated D20 reference review

Real static Godot 4.6.3 Mobile/Vulkan captures of the user-provided engraved D20. This project is separate from the application, Jolt collision bodies, outcome mapping, UI and release workflow.

Input `d20_obsidian_gold.glb` SHA256: `c5d971370fae51328461cbd220293d9445a14d7fd6f182b623f52551dbb8fa27`. The input and `.blend` are delivered privately as `D20_Art_Assets.zip`; the public repository contains the reproducible tools and actual captured evidence. Put the two archive GLBs beside this `project.godot` before running. No PC action is required of the user; this experiment was already executed in the cloud workspace.

Generate the separate shallower-inlay candidate using a Blender installation with its glTF addon and NumPy:

```bash
blender --background --factory-startup --python-exit-code 1 --python build_inlay_candidate.py
python3 audit_geometry.py --candidate d20_inlay_refined.glb
godot --headless --path . --editor --quit
```

Capture the candidate and original with identical light/camera parameters:

```bash
python3 run_review.py --godot /absolute/path/to/godot-4.6.3 --source d20_inlay_refined.glb --label candidate --disable-lod --final-studio --restore-clearcoat
python3 run_review.py --godot /absolute/path/to/godot-4.6.3 --label original --disable-lod --final-studio --restore-clearcoat
```

`Xvfb`, X keyboard data/compiler, a working Vulkan ICD and NumPy/Pillow for the audit are development dependencies. The runner accepts `--xvfb`, `--libraries` and `--vulkan-icd` for portable Linux installations. It starts its own TCP X display and checks the reported renderer, source hash, 23 imported meshes, real PNGs and script completion. It rejects renderer fallback, GDScript failures and crashes. Godot must have imported the GLBs first. An uncompressed GLB is intended; Blender's distribution can warn that its optional Draco library is absent.

The review reads authored clearcoat values directly from each GLB's JSON and restores that scalar extension in memory. Godot's native import of these files left clearcoat disabled. Albedo, metallic/roughness, normal and connected AO maps are retained. There is no emissive gold, numeral billboard, generic replacement stone material or change to collisions. The original file remains byte-identical.

Gold-only adjustment: Blender translates the 22 existing gold meshes by `0.023` model units along their outward normals. Body mesh and local topology remain unchanged; approximately `0.00685` units of genuine front recess remain. `audit_geometry.py` independently checks stone world positions/triangle count, twenty label directions, opposite pairs and original semantic texture pixels, then casts actual rays from glyph triangle centroids toward the oblique camera. Centroid counts do not measure visible pixel area.

Baseline profiles and diagnostic flags remain available. `--no-shadows` showed the dark numeral bands were geometry occlusion rather than light shadows. `--disable-lod` preserves full source geometry; it did not solve that occlusion. `--balanced-studio` and `--refined-studio` retain earlier experiments. Each new run snapshots its capture source alongside its PNGs and receipts.

See [the actual review and evidence](../../../docs/research/D20_REFERENCE_GODOT_PROOF_2026-10-12.md). Static render and geometry checks passed. M5 artistic acceptance, independent pixel critic, full temporal/Jolt/AVD integration and Nord 3 performance are OPEN.
