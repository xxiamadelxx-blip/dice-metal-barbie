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
