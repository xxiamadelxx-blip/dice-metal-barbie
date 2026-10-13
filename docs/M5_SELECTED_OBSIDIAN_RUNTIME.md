# Selected first obsidian in the actual game — 2026-10-13

The user selected the first/left Godot material reference. The original GLB and
HDR are pinned in `src/assets/approved_m5/README.md`; darker original gold and
all imported materials remain intact. These private inputs are not published
as repository binaries. No new material bake or geometry was generated here.

The D20 attaches to actual single-die and M4 mixed-pool Jolt bodies. The overhead
orthographic camera, canonical collider, D20 mass 0.045, number mapping, outcome
selection and RNG remain unchanged. The original reference's neutral HDR,
white ambient 0.8, key 0.8 and fill 0.35 are used when selected inputs exist.
Absent inputs retain legacy rendering. Lighting is global and was therefore
regression-captured across all eight modes.

Core now emits `critical_visual_requested` under the existing natural-1/20
selection conditions; main presents the aura. This removes the forbidden
core-to-visual import. The pool spawn handler retains real table-contact
tracking and decorates only canonical D20 bodies.

## Actual local evidence

- Godot 4.6.3, Jolt 120 Hz, native Linux Mobile Vulkan/llvmpipe, 720×1280.
- Actual main-scene harness: exit 0, no failed checks; D20 top/result 10;
  genuine simultaneous `1d20+1d6` produced 16 + 3 = 19.
- Real unchanged collider points, mass, camera, selected-art attachment and
  presentation signal connection checked. Full screenshots and 182-frame
  24fps fixed-step movie retained with the receipt. Movie rate is simulated
  capture time, not real-time performance.
- Eight live full throws: D4=2, D6=4, D8=3, D12=7, D20=8, D10=3,
  single D100=99, D100_PAIR=57. 1,285 decoded frames audited sequentially,
  57 exhaustive sheets, zero black frames after GO; per-frame metrics PASS.
- D20 frame 25 flagged a repeated-frame interval. Actual frames 0–27 show the
  previous settled D12 before the first visible D20 at frame 28. This is a
  recorded start/render delay, not evidence of a frozen in-progress D20.
  The warning remains in the report. Native throughput 9.47–10.62 fps on
  software rendering: nominal video 24fps is not 24 unique engine frames/s.
- Godot native checks: D20 geometry, M4 formula, critical aura, engraved
  assets with selected private art, physical pool and real reroll all exit 0.
- Router contracts: 24 tests; Gauntlet contracts: 25 tests, all passed.
- Architecture PASS_STATIC_ONLY, security PASS_PATTERN_ONLY; no gate removed.

## Adversarial self-review and remaining gates

The actual overhead captures were inspected against the selected oblique
reference. The surface is the selected neutral black polished material, but
some settled poses show almost no reflected strip and the numeral contrast
is low. This remains an artistic/legibility issue. No material, brighter gold,
exposure or camera substitution is disguised as the chosen reference.
Other dice still use their existing assets: this is a D20 integration step,
not a completed matching set or artistic M5 acceptance.

Independent Qwen is NOT_VERIFIED locally (Ollama/Docker absent). The canonical
CI entry previously sought only a host Ollama executable even though setup
starts `dice-gauntlet-ollama` in Docker. It now uses the verified running
container when no host binary exists. Contract tests cover running/stopped
container routing; they do not fabricate a model response. Only real
SHA-matched Qwen output counts, and its findings still require triage.

Selected-input Android/AVD export, OnePlus Nord 3 installation, FPS and visual
acceptance are NOT_VERIFIED. Public CI does not contain the private selected
inputs. Keep PR #23 draft and M5 open. Next: triage actual Qwen CI output,
improve overhead reflection/readability with the selected material and gold
preserved, then rerun exact-input temporal/Android checks before matching the
remaining dice. Full proof videos/PNGs/JSONL and exact selected assets are in
the private runtime evidence package, not public repository files.
