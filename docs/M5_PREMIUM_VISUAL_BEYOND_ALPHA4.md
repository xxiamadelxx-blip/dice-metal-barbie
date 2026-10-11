# M5 visual production: quality beyond Alpha 4 (2026-10-12)

**The user clarified that Alpha 4 is a UX reference, NOT a graphics-quality target.**
Keep interaction flow, quick history/pool, minimalist seven-die footer. New Android Godot renderer must surpass former web UI in premium material finish. No ugly grey concrete table, black plastic/polyhedron dice, or crude square toy borders.

## Observed exact native defect
Actual 720×1280 `native-01-launch.png` from [Gauntlet #38180995190](https://github.com/xxiamadelxx-blip/dice-metal-barbie/actions/runs/38180995190/artifacts/11718066256): green-black cloth now appears but lacks convincing directional surface highlight, slate-blue D20/D12 broad diffuse polyhedron facets and oversized box border rails. Earlier critical source stage proof exists; quality NOT ACCEPTED.

## Implementation candidate
1. `Premium._stone_pbr_for_glb()`: reduce the graphite plastic diffuse, use low-metal volcanic glass and narrower GGX clearcoat reflection; authored actual Blender GLB geometry and original engraved numerals remain unchanged.
2. `main._make_world()`: lower over-bright ambient and cool fill while retaining directional/rim. No changing approved fixed 90-degree camera.
3. `BeveledBox.create()`: one draw-call procedural chamfered ebony rail meshes; keep original four `StaticBody3D` BoxShape3D collision/rail extents untouched. Lacquered ebony material with real PBR coat instead of squared galvanized slabs.
4. Correct genuine multibounce velvet test: prior native check failed at 0.35s only because second actual physical Jolt contact had retriggered pulse. Now expect recovery after actual roll finished and 0.36s of no further contact. Do NOT bypass contact realism.
5. `tests/m5_ebony_rails.gd` proves four genuine bevel visuals + unchanged physics and lacquer; source native 24fps/full all-frame/AVD and original screenshot review required. Mobile frame rate and user aesthetic still OPEN.

## Not finished
Actual 3D fibrous velvet anisotropy at arm's-length mobile resolution, true die edge/facet micro-polish, realistic contact-tied audio/haptics, full dark-wood and brass finish, die-origin nat20/nat1 polish, Nord 3 hardware performance. Artistic approval is NOT an automated job status.

## Exact 2026-10-12 contract failure and repair

[Previous exact-source Gauntlet #38181403900](https://github.com/xxiamadelxx-blip/dice-metal-barbie/actions/runs/38181403900) **native FAIL** during `tests/engraved_assets.gd`: five `D4/D6/D8/D12/D20 obsidian metallic response outside physical-art budget`. The actual strict art regression requires source `_stone_pbr_for_glb().metallic` in **[0.15, 0.35]**, while first edited pass was 0.06. We restore **0.20** with retained GLB mapped roughness/normal and dark glass clearcoat; do **not** change the acceptance threshold. No screenshot of the failed source's ebony rails was generated: new same-SHA native/Godot visual evidence required before any art judgment.

## Exact Godot image finding: glass needs real studio reflections

Original native frame #38181811827 (artifact 11717973108) includes all 18 captured screenshots, true physical floor-contact and recovered-felt frames. Although engine geometry, texture and D20 physical result passed, hero D20/D12 still looked flat blue-grey. The practical cause was studio light sources outside their own attenuation radii: y6.0/range4.8 and y6.5/range4.4, both farther than their influence from the 0.7-high display dice. Move sources inside their real ranges, keep 90-degree camera, and add source reach contract. Tint authored imported source albedo darker without losing PBR normal/roughness.

Native color critic former B-minus-R blue pixel count was inappropriate for TRUE black obsidian. Replacing it does not waive area verification: the same pixel minima 13k/19k/14k/9k remain and now measure dark object relative to the SAME rendered velvet frame. Stronger silhouette contrast threshold (10 instead of 4) and additional independent facet luminance spread (8-12) required. User visual acceptance is still OPEN, exact new native frames must be inspected.
