# Measured D20 optimization — 2026-10-13

Blender4.0.2 reduced canonical visual80352->20146 triangles (74.9278%). Per-object weld+collapse preserves maximum sampled bidirectional vertex/triangle-surface error0.000318156 below0.001. Not a continuous Hausdorff proof. All21 mesh Euler characteristics, connected-component counts and manifold states match welded baseline; mesh holes and6/9 underbars retained. Original glyph unwelded seams repaired before collapse.

Naive coplanar pass removed108 triangles only. First20074 candidate rejected because one planar cap was degenerate under stringent orientation audit; per-object ratios rerun to meet unchanged0.001 normal tolerance. Whole-volume PCA was demonstrated unstable under changed vertex sampling; original and optimized GLBs checked by their flat front caps instead, max final normal residual0.000456. Failure not hidden.

Original embedded PBR image payloads exact. Final SHA2568cfb2fffc68bf60a5824d861e77f1e322aa18f3e5c774bf9c4700e16bfd2247b. Actual Godot4.6.3 Mobile Vulkan llvmpipe import20146 triangles/21meshes;20/20 expected top-value poses photographed and self-reviewed full contact sheet plus6macro. Same fixture lighting raw before/after mean RGB-byte absolute difference0.016116; not art acceptance. Exact canonical collider untouched; real Jolt settled3.2167physicsseconds/top11, identical final position to baseline. Actual final optimized Blender Cycles32samples render included.

Private Library package libfile_a9dbbd44f47c8191ae2dab8ce5b67fe9, comparison libfile_8ad4fba89f8c819188a8bb69d68fe4c8. Includes baseline/final.blend/GLB, optimizer, topology/geometry/normal audits, all20 actual PNGs and Godot repro. No binary published publicly.

Next: real game integration with preserved collider/results; existing architecture core->visual FAIL, full same-source24fps, independent critic, Android/Nord3 and premium art acceptance remain OPEN. Preflight contracts/security PASS, local Qwen unavailable. No phone FPS inferred from fewer triangles.
