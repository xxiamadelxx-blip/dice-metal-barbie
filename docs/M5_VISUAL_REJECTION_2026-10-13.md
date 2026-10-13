# User rejected current obsidian rendering, 2026-10-13

The user explicitly rejected the enlarged actual game capture as low quality.
This supersedes the earlier builder's description of overhead lighting as an
improvement. M5 visual status is FAIL / NOT ACCEPTED, regardless of physics,
image-metric and source-test results. Do not copy this look to the remaining dice.

## Observed defects

- Stair-step silhouette, numeral curves and fine engraving edges in the
  720×1280 capture; reflective seams produce isolated bright pixels.
- Flat triangular grey/black planes and weak visible surface detail do not
  convey the polished obsidian target at the game scale.
- Engraving reads as a thin flat gold contour at the delivered pixel density.

## Diagnostic execution

Actual Godot 4.6.3 Mobile/Vulkan scene, same frozen poses, unchanged overhead
camera and exact selected GLB/HDR: compared no AA, 2× MSAA, 4× MSAA, SMAA and
2× linear render scale at 720×1280; additionally rendered actual 1440×2560
frames with 4× MSAA. These are staged diagnostic captures, not real rolls or
phone performance measurements. Production rendering settings were not changed.

The project currently has no explicit 3D antialiasing setting. AA and native
higher resolution improve edge/numeral smoothness, but the flat stone
appearance remains in the original 1440-pixel engine output. Therefore the
problem is not merely the user's zoom or image compression. No new visual PASS.
Official [Godot antialiasing reference](https://docs.godotengine.org/en/4.6/tutorials/3d/3d_antialiasing.html)
distinguishes edge sampling, specular aliasing and supersampling cost.

Direct inspection of the immutable GLB's embedded maps: albedo is entirely
black; the 1024×1024 tangent normal has small XY variation (all channels
combined 121–255, Z is 255), and roughness is stored in green of the ORM map.
This is the selected author's procedural material, not a photographed
obsidian surface. The previous uniform neutral fill makes some facets visible
but cannot itself create believable surface or engraving detail.

## Independent critic outcome

The actual canonical run [#38382383419](https://github.com/xxiamadelxx-blip/dice-metal-barbie/actions/runs/38382383419)
artifact `engineering-entry-and-qwen`, id `11803489788`, was downloaded and
read. At source `eebae493c025e44c67e8ffbfe07e74f2562966fb`, the recorded critic
status is NOT_VERIFIED / TimeoutExpired, not a completed review. There is no
Qwen verdict on this lighting revision. The older successful d949 response
must not be reused as approval of eebae. Preserve the required critic gate.

## Corrective order

1. Treat the user's screenshot and selected first reference as the visual
   comparison; establish material, engraving and edge criteria at native
   game scale and a true engine-rendered macro inspection.
2. Rework the authored Blender surface/edge and engraving detail while
   preserving neutral polished black obsidian, original gold, canonical
   number placement and physical collider/mass/outcome. Keep original
   selected assets as the immutable control; use separate candidate files.
3. Validate candidates against that control in Blender and actual Godot
   Mobile. A smoother screenshot alone is insufficient artistic acceptance.
4. Select an AA level from authentic renders, then measure the exact input
   APK on Android and target Nord 3. Do not silently replace mobile rendering
   with expensive offline supersampling and call it phone quality.
5. Repair bounded independent-source review execution, obtain its real
   response on the new SHA, triage findings, and rerun the required genuine
   physics/full-eight-mode temporal checks before integrating candidate art.

No art correction is claimed complete by this diagnosis. This checkpoint
records the rejected artifact and concrete next authoring task. Existing
physics passes remain valid for their scope and do not override visual FAIL.
