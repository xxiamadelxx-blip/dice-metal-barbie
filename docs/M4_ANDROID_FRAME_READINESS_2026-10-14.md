# Resume: original Android framebuffer readiness

Run38464325751 at code3aa97f was inspected using actual job logs and SHA-verified artifacts. Android booted and completed all eight baseline physical modes. Its later M4 step failed because the original post-tap screenshot had zero pixels above difference16 in crop(17,106,703,510); the required count is greater than7500. The two PNG files are not byte-identical, so the finding concerns the actual gate's pixels, not file equality.

A fresh Godot4.6.3 GUI input check pushed real mouse press/release events through the viewport at(50,97). The actual button rect is(25,73,51,48) and the actual advanced panel became visible. This confirms the native hit target; it is not proof of Android input delivery or timing. Delayed AVD presentation remains the hypothesis to verify in the next exact-source run.

The AVD driver now waits up to20s for original ADB pixels instead of assuming one second is sufficient. It never repeats the toggle tap, retains every stale screenshot, and times out on unchanged frames. All previous regions/count thresholds remain: drawer7500, reroll/history drawer8500, full-history15000. The full-history per-pixel threshold remains18; other stages remain16. Dimensions must still be720x1280. The new helper tests run before the real emulator in the existing workflow and its sources are included in Qwen's review paths.

Local verification: seven synthetic pixel/retry tests PASS,28 engineering contracts PASS, shell syntax PASS, fresh native GUI input check PASS. Tests distinguish unchanged frames, updates outside the ROI, invalid dimensions, eventual refreshed pixels and the stricter history threshold. These unit fixtures are explicitly synthetic, not Android evidence. Actual new AVD behavior remains NOT_VERIFIED until CI.

A separate native visual gate still fails on the public fallback D4: measured facet_dynamic_range6.63, required8.0. Original images were inspected; no threshold was lowered and no artistic acceptance granted. Source3aa native eight-mode temporal job succeeded, but that public CI does not contain the private selected/polished D20.

Preserve the private D20 a02ce9 candidate and all prior Blender/Godot proof: libfile_8866648cfb708191b5d6de34cca0e63a. Its source/controls and its physics remain unchanged by this QA-only patch. Next: inspect the new Android readiness result/Qwen response, then correct D4 presentation/material contrast using real renders while preserving the strict critic and physical tetrahedron.
