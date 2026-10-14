# M5: user-selected polished black obsidian material intake

**Date:** 2026-10-14. **Scope:** isolated D20 experiment, not app release.
**Owner reference:** first image chosen by the owner on 2026-10-13, no purple veining.
**Selected real material:** [Procedural Obsidian by diaverx miky](https://www.blenderkit.com/asset-gallery-detail/92e31cbc-5b4e-4ead-a966-84bf106808c3/).

## Architecture decision

Do **not** replace Godot/Jolt, the user's approved overhead camera, the gold engravings, or M4.
Use the reference as a real authored Blender MATERIAL, not as an arbitrary flat color
or an image-generation mockup. Blendkit states the source is free; its
[Royalty Free / CC0 distinction](https://www.blenderkit.com/docs/licenses/)
and [redistribution terms](https://www.blenderkit.com/terms-and-conditions-2026/)
must be obeyed before shipping. The library can be browsed/downloaded for free
without user authentication, but **anonymous unattended API access is not yet proven**.
The selected asset's metadata license must be checked at source.

An exact-source, fail-closed, credential-free API probe was added as
`tools/materials/probe_blendkit_obsidian.py`: it checks the UUID, exact name,
MATERIAL type, legal license identifier, free status and valid Blender file signature.
It refuses guessed substitutes, paid files, empty responses and unsigned URLs;
it never logs a resolved signed download link. Raw third-party .blend data stays in
runner `/tmp` and is **not committed or uploaded in artifacts**.

A separate Blender/Cycles-only lookdev script,
`tools/materials/preview_blendkit_on_d20.py`, appends the selected material
onto the pre-existing physically sculpted/Boolean-engraved D20 face material
slot, leaves all twenty gold meshes and satin bevel materials alone, and renders
**two authentic Blender PNG images**: oblique inspection and overhead.
Geometry invariants are asserted; a 1000x850 decoded-pixel/variance gate
rejects missing/blank frames.

**Critical GLB constraint:** a procedural Blender node material is *not
automatically a Godot PBR texture*. Even if the source renders beautifully,
an approved production candidate would still require documented bake of
Base Color / Normal / Roughness / AO, GLB export, actual embedded channel
check, import to Godot **Mobile**, and visual + Jolt temporal proof. A successful
Cycles screenshot is not a Godot look or release PASS.

## Execution proof and limits

- BRDF surface-splitting regression fixed in `tools/visual/d20_brdf_lab_capture.gd`,
  SHA `c366362c0918412db4d183b0b93870b6afe566cc`.
  Real Godot 4.6.3 Mobile/Mesa [CI #38590355911](https://github.com/xxiamadelxx-blip/dice-metal-barbie/actions/runs/38590355911) **SUCCESS**.
  It is a runtime test correction, not a solved artistic material.
- Initial source proof committed at `6983d3bee61d79a95dd2bece1170d1142107f664`.
  [Real source intake + Blender test #38590931873](https://github.com/xxiamadelxx-blip/dice-metal-barbie/actions/runs/38590931873) launched;
  **result must be inspected**, the successful download/material render is **NOT_VERIFIED** at authoring time.
- All source GLB checks use independent published D20
  SHA256 `ec7bcee05f9d6b571b1db0db4ebc09d726b1aedd53a53159c067032c7c74987f`.
- The cached source artifact from run `38281898713` is temporary. If expired,
  regenerate from exact self-authored `tools/blender/learn_codex_d20.py`; never
  silently switch to another person's protected GLB.
- Godot Mobile bake equivalence, source asset redistribution/export approval,
  interactive Jolt roll/visible-number agreement, real Android FPS and
  independent aesthetic acceptance all remain **NOT_VERIFIED**.

## Acceptance next

1. Inspect the exact-source anonymous intake log and license/format receipt,
   including real source failure if any; avoid two identical retries.
2. When genuine Blender PNGs exist, compare the black-glass faceting and gold
   recessed numbers to the user's selected material and the previous D20.
3. Only then implement a real procedural-to-PBR bake and test exactly the same
   resulting GLB in Godot Mobile, before touching the actual APK.
