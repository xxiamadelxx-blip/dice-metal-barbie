# M5 research: actual D20 rendering load from 500K through 50M triangles, 100 exact increments

**Date:** 2026-10-14. **Gauntlet:** synthetic renderer capacity experiment PASSED, free polished obsidian source selection NOT_VERIFIED, Android Nord 3 and **single 50M unique-triangle D20 NOT_TESTED**. Current milestone M5 remains OPEN. Work only on isolated `experiment/m5-learn-codex-d20`. No changes to app gameplay, Jolt face authority, actual approved material, `main` or Draft PR #23.

## Immutable source and proof

- **100/100 steps MEASURED**, not merely requested or synthetically fabricated, actual [Godot 4.6.3 Mobile cloud run #38599056847](https://github.com/xxiamadelxx-blip/dice-metal-barbie/actions/runs/38599056847) **SUCCESS**, tested source `7743e5a8828bd5b90b0554ddc77f6d68aed6a3c4`. A real 50,000-triangle procedural subdivided ico-sphere was rendered with `MultiMesh` instance counts 10, 20, ... 1000. Exact submitted triangles: 500,000 per step, from 500,000 up to 50,000,000. Four independent runner shards [1–25], [26–50], [51–75], [76–100].
- The actual Godot engine primitive count `Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME` matched requested triangles **on every one of all 100 rows** (verified from original downloadable JSONL); Godot reported 1 draw call. Original 640×640 PNGs from stages 1, 10, 20, 50, 75, 100 are preserved as workflow artifacts.
- Source event files / exact GitHub artifacts: [aggregate 100-stage report #11913003014](https://github.com/xxiamadelxx-blip/dice-metal-barbie/actions/runs/38599056847/artifacts/11913003014), [stages 1–25 #11912792453](https://github.com/xxiamadelxx-blip/dice-metal-barbie/actions/runs/38599056847/artifacts/11912792453), [26–50 #11913002570](https://github.com/xxiamadelxx-blip/dice-metal-barbie/actions/runs/38599056847/artifacts/11913002570), [51–75 #11912512638](https://github.com/xxiamadelxx-blip/dice-metal-barbie/actions/runs/38599056847/artifacts/11912512638), [76–100 #11912567961](https://github.com/xxiamadelxx-blip/dice-metal-barbie/actions/runs/38599056847/artifacts/11912567961).
- Runtime: Godot 4.6.3 Mobile rendering mode, **Mesa llvmpipe (LLVM 20.1.2, 256 bits) on Ubuntu GitHub Actions**, viewport 640×640, MSAA disabled, no Jolt, no gold, no PBR textures. **NOT Android, NOT OnePlus Nord 3**, not one 50M unique-triangle GLB. Four warmup frames per shard, then only two wall-clock frames at each stage. `1000/ms` is a rough diagnostic rate, **not sustained GPU FPS**. Different shard CPUs have different speeds, and stage 25→26 and 50→51 show discontinuities.
- The prior [#38597960757](https://github.com/xxiamadelxx-blip/dice-metal-barbie/actions/runs/38597960757) failed missing X11 library; fixed X11 runtime. [#38598202244](https://github.com/xxiamadelxx-blip/dice-metal-barbie/actions/runs/38598202244) succeeded technically but its 1350ms time-limit ended early, giving only 4 measured stages; changed real approach to warmup+bounded 12s per frame, no premature stoppage. [#38599032529](https://github.com/xxiamadelxx-blip/dice-metal-barbie/actions/runs/38599032529) was canceled by replacement on exact GDScript newline fix. **Final #38599056847** has all four matrix jobs and final aggregate SUCCESS, 100 measured, zero missing.

## Exact visible performance landmarks

| Stage | GPU submitted triangles | Wall-clock frame, ms | Approx. wall-clock inverse, frames/s |
|---:|---:|---:|---:|
| 1 | 500,000 | 57.27 | 17.46 |
| 2 | 1,000,000 | 98.76 | 10.13 |
| 10 | 5,000,000 | 430.90 | 2.32 |
| 20 | 10,000,000 | 837.68 | 1.19 |
| 25 | 12,500,000 | 1041.68 | 0.96 |
| 26 | 13,000,000 | 1501.58 | 0.67 |
| 50 | 25,000,000 | 2867.17 | 0.35 |
| 51 | 25,500,000 | 2045.25 | 0.49 |
| 75 | 37,500,000 | 2897.85 | 0.35 |
| 76 | 38,000,000 | 4252.36 | 0.24 |
| 80 | 40,000,000 | 4585.14 | 0.22 |
| 90 | 45,000,000 | 4909.48 | 0.20 |
| 95 | 47,500,000 | 5413.36 | 0.18 |
| **100** | **50,000,000** | **5660.54** | **0.18** |

**Main conclusion:** software GPU can render the full 50M triangle *instanced scene* at extremely low throughput; this is NOT proof of feasibility for a unique 50M triangle die on a mobile GPU. A distinct analytic, **unmeasured**, closed genus-0 indexed mesh estimate for one 50M-triangle object requires roughly 600MB decimal of 32-bit indices plus 1.2GB decimal of 48-byte vertex data (~1.8GB geometry alone; potentially ~7.2GB without index sharing) before copies, render buffers, textures, numerals, physics and driver. Those are hypothetical buffer estimates, not measured RAM.

## Polished black obsidian material and model parsing

**Source audit:** [10 actual HTTP metadata checks, #38598528322](https://github.com/xxiamadelxx-blip/dice-metal-barbie/actions/runs/38598528322) PASS with [original JSON / artifact #11911032615](https://github.com/xxiamadelxx-blip/dice-metal-barbie/actions/runs/38598528322/artifacts/11911032615). Eight HTTP200 source listings and two HTTP403 BlenderKit listings. HTTP200 is **not** a texture download. Zero licensed owner-approved PBR files were acquired; exact Blendkit metadata and material `.blend` remains denied. Do not repeat identical blocked requests.

| Candidate | Availability / verified content | Action |
|---|---|---|
| [Exact owner-selected BlenderKit Procedural Obsidian](https://www.blenderkit.com/asset-gallery-detail/92e31cbc-5b4e-4ead-a966-84bf106808c3/) | HTTP403, no genuine file or source license metadata accessible | Correct reference but blocked, **do not substitute fake** |
| [Second BlenderKit procedural obsidian](https://www.blenderkit.com/asset-gallery-detail/d735310a-61f2-4cc9-87a9-aa883bd54d7a/) | HTTP403, no file | Not an alternate solution yet |
| [Sketchfab D20 Polyhedral Dice by pixel_mesh](https://sketchfab.com/3d-models/d20-polyhedral-dice-3e9f731177e5458986df6f1c2f690dd7) | HTTP200, public listing specifies **black obsidian**, nickel, red plastic variants; source model CC BY as listed, mesh/texture bytes not downloaded | Closest directly named black obsidian model reference, inspect actual materials before use |
| [CraftPBR polished black obsidian](https://craftpbr.com/material/LxSKwsj6ZHobzuMYDcva) | HTTP200, page states CC0 maps albedo, normal, roughness, metallic, AO, height; sign-in to download, source prompt includes purple neon reflections | **Rejected** due purple and auth gate |
| [Poliigon Knapped Obsidian](https://www.poliigon.com/texture/knapped-obsidian-stone-texture/11179) | HTTP200 but paid asset | Reject for zero-cost |
| [CGAxis Black Obsidian](https://cgaxis.com/product/black-obsidian-6727/) | HTTP200, interesting glossy PBR but credits/subscription required; not proven free | Reject for zero-cost |
| [Poly Haven](https://polyhaven.com/) | 100% CC0 asset catalog API queried; only ambiguous grey Cartago hit, not obsidian | Useful future library, no matching texture validated |
| [ambientCG](https://ambientcg.com/) | CC0 catalog API queried; `search=Obsidian` returned unrelated items | No obsidian match validated |
| [cgbookcase](https://www.cgbookcase.com/textures) / [Opeture](https://www.opeture.com/) | General open texture catalogs HTTP200, no validated polished obsidian specific source | Potential future search |

Independent actual-material preview pass: [25 Blender MIT-license original shader previews #38599475260](https://github.com/xxiamadelxx-blip/dice-metal-barbie/actions/runs/38599475260), [artifact #11913326956](https://github.com/xxiamadelxx-blip/dice-metal-barbie/actions/runs/38599475260/artifacts/11913326956), upstream [Infinitode/Material-Library](https://github.com/Infinitode/Material-Library) LICENSE MIT. Real preview gallery + hashes and 25 named `.blend` entries were inspected. Colorful transparent glass materials, **none artistically approved as solid polished black obsidian**, no purchased/unsigned material, no purple substituted into production.

## Follow-on execution/acceptance

The **rendering stress route** is now complete and frozen at successful exact source SHA. For the user's originally envisioned single ultra-dense D20, the next experiment must create and import one genuinely high-poly *unique indexed* die at selected polygon counts, track actual GPU/system memory and safe failure, run real Android AVD or physical Nord 3 before making a mobile performance claim. Given 59,276 actual triangles on the current engraved D20 (50,372 of them from gold text), prototype LOD/gold glyph optimization first. Only legitimately retrieved black polished obsidian PBR source from the owner's chosen original or an explicitly approved replacement can be baked into Godot; inspect the real Blender and Godot renders before publishing an app skin.

**Independent vision-capable critic / owner aesthetic signoff:** NOT_VERIFIED. **Source original single 50M mesh:** NOT_TESTED. **On-device Nord 3:** NOT_VERIFIED. **Selected material acquired and baked:** NOT_VERIFIED. Technical 100-stage proof is PASS **only for the multi-instance software GPU load test**.
