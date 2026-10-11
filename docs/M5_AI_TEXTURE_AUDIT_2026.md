# M5 AI 3D/textures audit and actual canonical D20 A/B experiment

2026-10-12. User confirmed Alpha4 is a **UX reference only**; actual graphics must surpass it. Keep M4 accepted physical behavior and previously authored Blender assets. This document distinguishes installation feasibility, **real attempted AI**, and production art approval.

## Providers: tested feasibility, no imaginary capabilities

| Option | Evidence / actual capabilities | Cloud default | Decision |
| --- | --- | --- | --- |
| Dream Textures Blender add-on | [Official GPL-3 repo](https://github.com/carson-katri/dream-textures), [releases](https://github.com/carson-katri/dream-textures/releases): Stable Diffusion image generation, seamless/depth projection, upscaling. Linux installation is **manual**; GPU >4GB VRAM recommended, tested CUDA/Apple Silicon. Documentation does NOT guarantee accurate full PBR from every text prompt. | Existing GitHub Actions Ubuntu Blender runs **without verified GPU**. PyTorch/model dependency expensive; no real local model inference or addon installation verified. | Future optional pinned GPU research, **not mandatory CI**. |
| Meshy AI | [Official free terms](https://help.meshy.ai/en/articles/15696428-what-is-included-on-the-free-plan): limited credits/downloads, paid-plan-only API. [Retexture API](https://docs.meshy.ai/en/api/retexture): `enable_original_uv=true`, `enable_pbr=true`; generates new maps over an existing mesh. | Requires paid API credentials. Not called. | Optional, only after explicit spend approval. Never let AI replace physically numbered geometry. |
| Tripo AI | [Official API billing](https://platform.tripo3d.ai/docs/billing), actual 3D generator and texture service. | Paid by credits; not called. | Optional decorative tray prototypes, not authoritative D20 shape. |
| AI Render / BlenderGPT | Render stylization / Python generation aids; user-mentioned names are NOT proven to produce physically calibrated seamless complete PBR. | No audited/pinned production implementation. | Reference/editor assistant, not game-ready texture proof. |
| OpenAI image-generation | A **genuine AI material source image** was generated for this D20 experiment in the conversation, independently of Dream Textures. Texture was edge-blended and color-balanced offline. | Does not require service API in Android. | **A/B experiment completed on real canonical Blender D20 GLB, NOT shipped.** |
| Existing Blender/MeshLab/Material Maker/Python | Exact-sourced Boolean-cut, UV, source PBR, real Jolt physics, GLB; Material Maker real PTEX export still NOT_VERIFIED. | Blender/MeshLab/etc actual CI succeeded. | Keep current offline deterministic fallback, add AI-generated base-color as conditional input. |

## Actual A/B experiment, not a fabricated render

Original **real Blender D20** from GitHub Gauntlet [#38183827265](https://github.com/xxiamadelxx-blip/dice-metal-barbie/actions/runs/38183827265). Original visual GLB SHA256 `788aad2e9188949e4dd11fbb12bb5b85ddd25a238b2c1700226e9bb449a3ae5d`.

Generated image source: original ChatGPT image-generation output **1254×1254**; color atlas test **1024×1024**, edge-adjusted intermediate JPEG **256×256**. Its **only** role is an experimental *base-color image*. No actual generated Normal, Roughness, Metallic, Occlusion, Height, geometry, UV or numbers claimed. Base-color mean ~30.12 (0..255) after lookdev. No runtime AI/API.

Our offline script `tools/materials/ai_d20_glb_experiment.py` directly swaps only a glTF `baseColorTexture` image reference, appends new PNG without rewriting the original BIN, and asserts unchanged original `meshes`, `accessors`, original `materials` including tangent Normal/Roughness, original bronze geometry, and original GLB asset bytes. New experimental visual GLB SHA256 `47486f693b02f6e210edccff2866f6389fbe52356ebdab3f0d25a510a392e71a`. Separate standalone artifact remains in conversation, NOT in production repo assets.

CI now runs `tools/materials/test_ai_d20_glb_experiment.py` on the same freshly generated D20 GLB with a **synthetic fixture**. Passing that CI proves the safety of the source preservation and that Python can rewrite/read an actual glTF image, **not that AI inference was run in CI** or that the material looks premium.

## Strict promotion gate

- Experimental image is low-detail after 256² test downsampling and carries plausible *baked highlights*, so it is **not** automatically trustworthy as an unlit material. Higher-res material, independent physical roughness/normal, AO cavity bake with nonbinary tonal gradation and proper color management required.
- Original 1024² D20 Cycles AO file on prior exact run had almost only 0/255 and a 1-pixel stripe; its "success" histogram guard was insufficient. It is NOT accepted as final PBR AO. Bake range/gradients require deeper revision.
- **No default game art swap** until real Blender preview, original Godot/Mesa 720×1280 closeup, actual Android AVD screenshots, physical Jolt 24fps, and user artistic approval. Generated mesh must never be used for collision or face numbering.
- All core old models and textures remain available as A/B controls. No paid key or runtime internet. Any future Dream Textures add-on must pin release/hash/version and be optional only for dedicated GPU worker.

Research verdict: working offline AI **image-to-existing-3D visual material bridge** on the real D20, but **AI candidate quality / final Godot appearance UNVERIFIED**. Do not assert provider integration or full PBR is accomplished.
