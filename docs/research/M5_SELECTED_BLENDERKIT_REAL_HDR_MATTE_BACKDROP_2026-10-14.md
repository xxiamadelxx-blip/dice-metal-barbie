# M5 recovered BlenderKit polished obsidian: real HDR reflections with invisible light panels
Date: 2026-10-14. Isolated branch `experiment/m5-learn-codex-d20`. **Engineer-only experiment, owner artistic approval OPEN.**

## Why the previous iteration appeared stuck
The working local private Godot test project was available and already had **one genuine 500,000-triangle die** and rebuilt selected BlenderKit normal-map on its own 2048² UV layout, not just a blocked source download. Repeated user-facing progress without preserving a new result was wrong. Recovered local private runtime:
- `/mnt/data/dice_private_render/native_bake_polished/D20_500K_SELECTED_REAL_OBSIDIAN_hybrid_gold.glb`
- `/mnt/data/dice_private_render/assets/studio.hdr`
- `/mnt/data/dice_private_vulkan/vulkan-icd/lvp_private_runtime.json` with Mesa software Vulkan llvmpipe 20.1.2.
The selected source remains the authentic user-selected **Procedural Obsidian by diaverx miky**. Do not replace it with synthetic gray/purple/CC0 placeholders. In 20-face Godot checks, hybrid-gold visible pixels rose significantly under identical HDR/camera; the geometric 500k D20 and digit meshes remained unchanged.

## Concrete new correction
Previously displaying HDR as visible `Environment.BG_SKY` exposed huge white light-card shapes *in the frame*. Switching to `Environment.BG_COLOR` hid them but also removed specular reflections from the flat mirror-like stone on the Vulkan Mobile path, leaving nearly featureless black.

**Actually authored/tested fix:** retain `Environment.BG_SKY` and original HDR reflections, place a large **unshaded opaque charcoal QuadMesh behind the die and in front of the sky** only for the camera; disable its cast shadows. This camera-facing matte hides visible studio light panels without replacing the original node material, changing the mesh, changing the GLB, tampering with Gold meshes or losing HDR sky reflections.

Code: `tools/visual/d20_selected_private_matte_ibl_capture.gd`. CLI expects the recovered private user GLB and original HDR **in a private local Godot lab**, NOT in public repository.

### Actual real engine tests
- Engine Godot **4.6.3**, native renderer **Mobile/Vulkan**, software adapter **llvmpipe LLVM 20.1.2**, screen 1024×896, MSAA4x, 8 settled native frames per capture.
- One D20 with **exact indexed 500,000 triangles**, 21 actual mesh objects (1 obsidian + 20 gold glyphs) asserted **by live Godot mesh accessors** on every new native capture, not via synthetic image generation.
- Raw old studio-sky yaw150 baseline plus tested alternative HDR yaw70/exposure1.0/fill0.6, yaw150/exposure1.0/fill0.6, yaw128/exposure1.06/fill0.85. A BG_COLOR negative control confirmed reflection lost.
- Candidate visual tradeoff: yaw**128** allows a narrower off-center grey sheen and keeps face17 a readable black/gold; yaw150 brings up central face17 as an overly grey flat triangle; yaw70 buries faces in almost uniform black. **No subjective claim that all faces look premium**.
- Original complete 4-way real Godot screenshot contact sheet, full 4 native PNGs, original studio HDR, exact private genuine PBR 500k hybrid-gold GLB, logs and script in the **personal Library**, path:
  `/Дайс/D20_500K_REAL_GODOT_MOBILE_MATTE_HDR_FIX_PRIVATE.zip`
  ZIP SHA256 `24d90d17c18fe43cb4bcbd48a30c560507dd04ab7a307ce6b95b5645ebbcb2ec`, model GLB SHA256 `f7208af5e40a536db59476f1cb5a67993de6c2f84c7e3cfb135e5ea9152e271f`, bundle 10,487,110 bytes.
- **No licensed private .blend, PBR PNGs, packaged GLB or HDR included in public GitHub.** User-private Library is the recovery/supply path.
- Godot renderer continuity caveat: one *initial* trial without the bundled Mesa Vulkan ICD silently fell back to OpenGL Compatibility; that output was excluded. Final 4 native comparisons from manual trials use the verified `renderer=mobile` + `llvmpipe LLVM20.1.2`, and no unverified mobile FPS claims.

## Gauntlet / following task
**Native HDR background fix: technical PASS**, real geometry/material unchanged. **Visual acceptance OPEN.** Current stone still mostly too black, and planar large specular patch still lacks spatially natural microcurvature; gold improved but not fully judged. Next step: calibrate real HDR light-card angular size/reflections and exact selected procedural bump in Blender then native Godot, A/B all twenty face poses. Do not conflate color-card removal with completed D20. Android physical OnePlus Nord3/Jolt gameplay, independent Qwen art reviewer, shader parity and actual game import still NOT_VERIFIED; leave `main` and Draft PR#23 unchanged.
