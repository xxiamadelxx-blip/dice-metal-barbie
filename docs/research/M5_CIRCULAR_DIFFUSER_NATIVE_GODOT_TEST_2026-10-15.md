# M5: physical circular diffuser / round softbox actual Godot Mobile experiment

**Date:** 2026-10-15. **Branch:** `experiment/m5-learn-codex-d20`. **M5 artistic acceptance remains OPEN.**

## Actual work and tests

Nine **circular** (not rectangular) RGBE panorama lighting variants were generated with a spherical angular-distance disk and feathered edges. One source variant is an annular/ring shape. Experiments preserve the original owner-selected private 500K D20 material maps, all 20 individually engraved gold digits, the convex Jolt collision mesh, canonical physics result, and the approved strictly orthographic overhead camera.

Real Godot **4.6.3 Forward Mobile Vulkan / Mesa llvmpipe CPU** snapshots were rendered for original `off` plus 9 variants at 720 × 1280 using the unchanged private D20 GLB. True round overhead 16° key at intensity 6.8 makes the top planar obsidian facet graphite gray, *not* more natural polished black stone; adding very weak fill/gold lighting barely changes that. Moving physically circular reflectors toward the sideways faceted mirror directions changes side-facet reflections, but overbright versions also look too gray and were **rejected**. A restrained side-lit `round_black_rim_single` was selected for **further experimental testing only**, not approved as a production skin.

The actual in-app native Godot Mobile/Vulkan Jolt throw using this candidate **completed successfully**. Physical top printed gold = settled Jolt result = UI result, all **11**; real 720×1280 screens saved **before**, **during** and **after** the physical motion. Logs also confirm exact original model source, 21 mesh parts, 500K triangles (stone 220K / gold 280K) and preserved original convex physical hull. No fake/shader-painted highlights or source texture changes.

An opt-in GDScript adapter and JSON source parameters have been tested locally and are saved in the private user Library source QA bundle. The adapter defaults to `off`, rejects an unknown variant, refuses a modified HDR file via exact SHA, and preserves the original world environment on every failure. **9 checks pass for genuine candidate, 8 for deliberately modified HDR.** No private licensed BlenderKit source was copied into public GitHub.

**Persistent full source, original native output screenshots, generated non-licensed HDRs and logs:**
`/Дайс/D20_500K_TRUE_CIRCULAR_SOFTBOX_IMPLEMENTED_REAL_GODOT_JOLT_QA.zip`.
Evidence SHA256 `5b4e7c6231bcbb2fc202c2c3cbc5b0490566010dfe43552ae0acc954fc237976`, size 6,492,374 bytes, contains 38 integrity-verified files. Original side-by-side PNG also saved separately as `/Дайс/D20_REAL_MOBILE_ROUND_DIFFUSER_BEFORE_AFTER_FULL_FRAMES.png`.

The generator alone is in public source `tools/visual/m5_real_round_diffuser.py`. The rest of the full tested opt-in integration is preserved privately; do not assert it has been merged into the public branch until the corresponding source commits succeed.

## Open

The body is still very small in the approved gameplay camera, rough and dark/graphite rather than artistically premium in several poses. Other reflection schemes would need independent human visual signoff. Native Mobile/Vulkan test used software rendering on desktop Linux; **no Android emulator or real OnePlus Nord3 device FPS/memory/thermal proof**. No stable APK, no code merged into main or M4 PR #23. Independent Qwen critic NOT VERIFIED.
