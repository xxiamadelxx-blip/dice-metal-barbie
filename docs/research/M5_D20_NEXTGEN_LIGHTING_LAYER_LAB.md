# M5 lighting laboratory: controlled diagnostics, not random shader tuning

## Motivation and scope
The owner asked to combine real console-grade/mobile-supported light techniques with a Blender artist's causal, component-by-component scene reasoning. The existing independently authored D20 has physically inset gold numerals and an accepted technical edge-halfspace gate, but Mobile looks silver/flat on some facets. Prior run #38286853449 showed disabling 3 OmniLights does not eliminate the washed facets. **Do not edit physical Jolt or declare premium art done.**

## Scene component layers
Keep SAME GLB SHA256 `ec7bcee05f9d6b571b1db0db4ebc09d726b1aedd53a53159c067032c7c74987f`, SAME camera, orientation, top-down art-test pose, exposure unless specific labeled pass changes it. Use actual Godot 4.6.3 Mobile on Mesa software Vulkan with original PNGs and engine logs, not generated images or false on-phone claims.

| Real diagnostic mode | Changed component | Diagnostic question |
| --- | --- | --- |
| `lab_reference` | No change; verified narrow50 Sky + PBR + three OmniLights | Real control |
| `lab_clay` | All D20 surface materials temporarily replace with flat neutral gray rough clay; ALL geometry remains | Is the issue caused by bevel/geometric topology rather than material? |
| `lab_normals` | Shader displays current view-space surface NORMAL in RGB | Are face/chamfer normals unexpectedly oriented or smoothed? |
| `lab_normal_off` | Disable source normal maps, keep real material surfaces and sky | Is normal-map micro-relief responsible for washed planes? |
| `lab_spec_off` | Disable coat and roughness-map highlights, keep shape | Confirm how much specular response drives the gray faceting |
| `lab_direct` | No Sky reflection or ambient, keep OmniLights | Distinguish direct light from IBL |
| `lab_ibl` | Turn off all OmniLights, retain Sky | Is the bright facet truly from radiance environment? |
| `lab_probe` | No Omni; ReflectionProbe UPDATE_ONCE, dedicated emissive studio quads on probe-only rendering layer | Can localized capture create controllable reflection detail in Mobile? |

ReflectionProbe in Godot 4.6 Mobile is an allowed alternative to screen-space reflections (SSR is Forward+ only). Probe `cull_mask=2` only sees fixture layer 2, `reflection_mask=1` applies reflections to die on layer 1, game camera culls layer 2, `UPDATE_ONCE` captures six directions over several frames. Test must **verify actual pixel effect**, not merely successful script creation. Never add screen-space bloom, emission on the stone or fake painted highlights to obtain misleading results.

Keep optional fog/dof/saturation OFF while debugging the obsidian because they confound the current material issue. LightmapGI for static velvet and larger PCSS soft shadows from Omni/Spot belong to separate, later cost-vs-art experiments. PSSR is PS5 Pro resolution reconstruction and **not** available as a Godot Mobile lighting component.

## Reproduction
- Source file: `tools/visual/d20_layer_lab_capture.gd` (self-contained derivative of the previous verified imported GLB renderer, but does not change old saved workflows).
- Native cloud test: `.github/workflows/d20-layer-lab.yml` downloads known Blender-source original GLB artifact from #38281898713, asserts SHA, generates previously verified real RGBE `narrow50` studio, imports with Godot, and captures eight actual engine PNGs plus logs.
- Output: `real_mobile_material_light_layers.png`, `real_material_light_layers.json`, all original `godot_lab_*.png` and capture logs. The comparison board only collates original PNGs.
- Every failure must retain original diagnostic artifacts; no green CI is equivalent to independent artistic acceptance.
- Minimum expected evidence: clay differs from source, normal pass has distinct pixel colors, IBL differs from direct; probe A/B is recorded even if unchanged and flagged `NO_PROBE_PIXEL_EFFECT`.

## Artist's causal loop
Observe defect in original source PNG → select exactly one diagnostic layer → change one controlling parameter → capture real Blender/Godot source images → inspect both geometry and material separately → independent visual critique if an actual independent critic is available → either keep with evidence or roll back and record why. 
No extra full-physics/Android Gauntlet per lighting dial adjustment. Preserve the source GLB, bevel width .010 and geometry face map; full Android/Jolt/24fps checks only after the user approves actual art.

## Status
Until the new workflow completes: native laboratory capture **IN PROGRESS**, ReflectionProbe benefit **NOT VERIFIED**, owner art acceptance **FAIL**. Never report app runtime effect or mobile hardware performance from Mesa cloud frames alone.


## First actual real-engine results, cloud run #38290410135

Evidence: [original 8-pass Godot Mobile run](https://github.com/xxiamadelxx-blip/dice-metal-barbie/actions/runs/38290410135), [original frames + logs artifact #11765217168](https://github.com/xxiamadelxx-blip/dice-metal-barbie/actions/runs/38290410135/artifacts/11765217168). Original comparison contact sheet: `real_mobile_material_light_layers.png`. The scene contains the exact same recovered independent GLB; no model edits between captures.

| Isolated captured layer | Image ROI luma mean, arbitrary 0..255 | Observed inference |
| --- | ---: | --- |
| Verified studio reference | 57.89 | Obsidian is gray on a few faces; art FAIL |
| Neutral gray clay | 95.30 | Planar geometry and engraved numeric cut are visible without specular panels; earlier raised-edge issue is not a protruding 3D lip |
| Real GDScript Normal RGB debug | 142.62 | Face planes have distinct normals, but this output is a diagnostic shader, not material |
| Disable Normal Map | 57.89 | Numeric image difference vs baseline is only 0.034/255 average in source ROI; micro-normal map effectively immaterial to current silver-flatness |
| Disable specular and coat, roughness 1.0 | 37.30 | Material reflection component dominates appearance; gold remains separate geometry |
| Direct light only, no Sky reflection or ambient | **8.68** | Direct lights alone cannot provide polished obsidian shape |
| Sky-only, Omni energy zero | 51.50 | Broad silver highlights persist from environment |
| Local reflection probe with Sky reflections disabled | **1.70** | **FAILED as a material solution**; too dark. This first version also accidentally placed fixture coordinates outside probe size 5 (half-extents only ±2.5), and the old probe-vs-sky difference was a misleading comparison. Do not claim ReflectionProbe benefit |

Mean ROI bounds x=250..779 and y=150..729 contain some background. They are useful for controlled A/B **not** perceived quality scores. Additional actual absolute difference ref-vs-normal-off mean 0.034/255 across ROI, bright altered pixels less than 0.02% with any-channel difference greater than 8.

The first strict native full diagnostic workflow **passed renderer execution and screenshot checks**, not artistic acceptance. The probe case demonstrates why a change in pixels compared against the wrong control is not proof of a working feature.

### Second controlled test
- Branch `experiment/m5-learn-codex-d20` files `tools/visual/d20_probe_lab_capture.gd` and `.github/workflows/d20-probe-lab.yml` move probe box to 12m, actually include the 2 reflector emitters, switch on emissive color instead of relying on unshaded bright diffuse and capture 12 real frames for `UPDATE_ONCE`.
- Compare same `lab_ibl` sky and `lab_probe_sky` with **Sky left enabled**; `lab_probe` with Sky reflection disabled remains only a negative control.
- [Live run #38291232045](https://github.com/xxiamadelxx-blip/dice-metal-barbie/actions/runs/38291232045). Until verified, actual improvement remains NOT_VERIFIED.


## Final local-ReflectionProbe falsification (run #38291232045, #38291827376, #38292234674)

Three independent actual Godot Mobile/Mesa render captures were executed on the SAME exact GLB hash `ec7bcee05f9d6b571b1db0db4ebc09d726b1aedd53a53159c067032c7c74987f`. All source engine PNGs and logs are kept in the failed-run artifacts, even though the strict ART gates were deliberately red.

1. [#38291232045](https://github.com/xxiamadelxx-blip/dice-metal-barbie/actions/runs/38291232045) artifact `11766376486`: increased probe size from 5 to 12, added correctly emissive fixture cards. Sky-only 51.50/255 mean ROI; Sky+probe **2.84/255**. `lab_probe_sky.png` and no-sky `lab_probe.png` were byte-for-byte identical. This is NOT proof of good localized IBL.
2. [#38291827376](https://github.com/xxiamadelxx-blip/dice-metal-barbie/actions/runs/38291827376) artifact `11767001159`: waited 12 actual `RenderingServer.frame_post_draw` signals instead of 12 game process ticks, inspected fixture layer independently. Captured emitter visible at outer edge of fixture-only frame, but probe image still 2.84/255 mean ROI. The proper GPU-frame timing alone did not solve it.
3. [#38292234674](https://github.com/xxiamadelxx-blip/dice-metal-barbie/actions/runs/38292234674) artifact `11766278091`: added an authored unshaded emitting **studio cyclorama sphere on probe cull layer 2** behind the softbox cards, invisible to the game camera on layer 1, in order to avoid black local radiance in most directions. Sky+local studio probe rose to **21.65/255** mean ROI (from 2.84), but remains visually **too black** compared to real Sky-only 51.50 and Codex premium reference. The fixture-only capture was almost uniform and failed the screenshot variance heuristic; its own screenshot is saved. The actual die render has some warm facet response, but no premium readable obsidian. **Do not claim artistic success.**

**Decision:** HOLD all three ReflectionProbe lookdev variants in the evidence archive as failed proof of technique. The local probe mechanism is supported by Godot Mobile, but *this authored setup did not improve the requested D20*. Do not copy it into production or replace proven Sky/IBL. Preserve the last readable experimental lookdev `narrow50` and its physical HDR axis correction. Further art direction should test narrower physically consistent highlights and facet-normal specular distribution in controlled diagnostic passes. The geometry halfspace, genuine engraved numerals, .010 satin bevel, and color/ORM numeric checks remain canonical. No PSSR, SSR, volumetric fog, GI changes, Godot Forward+ switch, or Jolt/Android changes have been made.

**Next practical steps:**
- Use the first successful 8-pass diagnostics as the source-grounded cause: normal map no change; silver facets from Sky and coat, not Omni or geometry.
- Test 1-2 stone face BRDF adjustments and specular card shapes against Sky `narrow50` in original Godot Mobile source captures, with fixed geometry/lighting per test; only accept if owner can actually see a difference for the better.
- A separate soft-shadow PCSS test could improve contact with table and LightmapGI could improve static velvet, but they cannot cure specular gray facets. Keep them out of this art gate until the core obsidian is approved.
- Real independent visual critic, verified actual spatial AO, Android/OnePlus Nord 3 and full Jolt/24fps acceptance remain **NOT_VERIFIED**. 


## Exact GLB BRDF separation (real Mobile evidence #38293631310)

[Real Godot 4.6.3 Mobile Mesa source A/B](https://github.com/xxiamadelxx-blip/dice-metal-barbie/actions/runs/38293631310), artifact `11767700064`, original PNGs `godot_brdf_*.png`, logs and `real_mobile_obsidian_brdf_comparison.png`. Same source GLB SHA256 `ec7bcee05f9d6b571b1db0db4ebc09d726b1aedd53a53159c067032c7c74987f`, physically unchanged numbers, edge normals, face geometry and studio narrow50 HDR. Material changes ONLY on two stone surfaces, never gold. Workflow `.github/workflows/d20-brdf-lab.yml`, source `tools/visual/d20_brdf_lab_capture.gd`.

| Captured real variant | ROI mean luma (0..255, background included) | Highlight fraction >100 | Independent visual interpretation |
|---|---:|---:|---|
| Reference F0 knob .50, source G roughness .17, coat .26/.09 | 57.88 | 8.51% | gray/silver planar faces, FAIL |
| `metallic_specular=.25` | 42.81 | 1.87% | meaningful suppression of silver; loses some sparkle, **controlled candidate only** |
| `metallic_specular=.12` | 32.11 | 0.78% | TOO DARK, reject |
| Coat disabled | 58.30 | 8.58% | does not solve gray faces |
| Roughness .24 flat | 54.83 | 8.38% | diffuse reflection still gray facets |
| Roughness .10 flat | 61.14 | 8.79% | sharper but brightens gray facets |
| Coat roughness .18 | 57.91 | 8.51% | negligible effect; avoid tuning clearcoat blindly |

**Causal result:** Godot 4.6 metallic_specular controls the specular reflections *including reflected sky*, whereas setting `specular_mode=DISABLED` only disables direct-light specular lobes. Godot official documentation warns `metallic_specular` outside .5 is not strictly energy-conserving; this is a **diagnostic parameter probe, not a physically verified premium-shader final value**. The significant flat-looking gray facets are driven primarily by sky specular strength and constant planar normals, not a missing clearcoat trick or excessive emissive gold. A higher-quality physically grounded solution needs actual local angular variation of reflected light (controlled normal microfield or controlled HDR card angular distribution) while retaining dark dielectric stone.

**Next study**: `tools/visual/d20_micronormal_lab_capture.gd` + `.github/workflows/d20-micronormal-lab.yml`, actual identical source GLB and narrow50 studio, compare `spec=.25` source normal and three subtle per-tile tangent-space normal lapping slopes .06/.12/.20 on face ONLY. All tangent-normal perturbations smoothly fade to zero at 5x4 tile borders; this is a temporary diagnostic shader texture generated procedurally by Godot, *not a claimed Blender AO or approved GLB*. Independent premium acceptance remains FAIL/NOT_VERIFIED until genuine source PNG review and user approval.
