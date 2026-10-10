# Installation and execution probe: creative desktop editors

**Target:** ephemeral GitHub Actions `ubuntu-24.04` x86_64 runner, **not** the Android device. Run [`creative-toolchain-probe.yml`](../.github/workflows/creative-toolchain-probe.yml), then inspect its `creative-toolchain-probe` artifact (`probe-report.json`, `apt-install.log`, command outputs, official Material Maker release download and checksum). This file does **not** assert success until actual CI logs prove it.

## Four new tools
| Tool | Installation candidate | Actual probe status at authoring | Runtime rule |
|---|---|---|---|
| Material Maker | Official release `RodZill4/material-maker` **1.7** Linux tarball pinned by upstream published SHA256 `c8e3b6f1993540875d26fe49645c91511bba36cda0412c715bd13249f7141647` | **FIRST RUN: installed, SHA-256 PASS, `--version` PASS** | Use only with verified executable + headless export of `.ptex`; else Blender/Python. Do NOT run unverified archive executables. |
| MeshLab | Ubuntu 24.04 official `meshlab` apt package (Universe) | **FIRST RUN: APT installed 2020.09, CLI without DISPLAY failed; Xvfb recheck pending** | Mesh inspection/cleanup only after package/runtime smoke; else Trimesh/Blender. |
| Krita | Ubuntu 24.04 official `krita` apt package (Universe) | **FIRST RUN: APT installed 5.2.2, CLI without DISPLAY failed; Xvfb recheck pending** | Optional painted texture/mask tool only after install/export proof; else GIMP/Python. |
| GIMP | Ubuntu 24.04 official `gimp` apt package | **FIRST RUN: APT installed 2.10.36, CLI `--version` PASS** | Optional image edit and batch workflow only after command and noninteractive proof; else ImageMagick/Pillow. |

## Existing established pipeline
Prior PR CI has independently exercised Blender 4.x generator/GLB/PNG, Godot 4.6.3 native renderer/Jolt/ARM64 export, and Python image critic. In this assistant's present ephemeral container (Debian 13), **OpenSCAD 2021.01, Inkscape, ImageMagick, FFmpeg and Trimesh 4.11.1** binaries/import were found. These checks confirm local availability only, *not* that they are installed on GitHub Actions Ubuntu 24.04 or inside Android. Existing Blender/Godot are driven in **GitHub Actions**; availability varies by runtime.

## Evidence levels
- `not_found`: package or executable not found.
- `install_failed`: apt/download/hash failure; no capability assumed.
- `installed`: package or unpacked executable present.
- `cli_ok`: bounded `--version` returns exit 0. GUI export/headless feature NOT YET VERIFIED.
- `gui_smoke_ok`: explicitly started under Xvfb; not necessarily useful for production.
- `headless_export_ok`: an authored test asset exported and validated. Required before unattended production use.
- `production_verified`: includes imported Godot scene and on-device release gates when relevant.

The probe must be allowed to **record failures rather than hide them**. It must never install packages on the user's phone, commit third-party executables into repository, or expose tokens. Material Maker official CLI syntax is `--export-material --target Godot -o <output_path> <input.ptex>` documented in [Material Maker command line docs](https://rodzill4.github.io/material-maker/doc/command_line.html). Without a real `.ptex` test asset, mark material export NOT VERIFIED.

## Sources
[Official Material Maker releases](https://github.com/RodZill4/material-maker/releases/tag/1.7) · [Official Material Maker CLI](https://rodzill4.github.io/material-maker/doc/command_line.html) · [Godot CLI](https://docs.godotengine.org/en/4.6/tutorials/editor/command_line_tutorial.html).

## First actual GitHub Actions evidence
[Ubuntu install and execution probe #38075529457](https://github.com/xxiamadelxx-blip/dice-metal-barbie/actions/runs/38075529457) finished **SUCCESS**, with uploaded artifact `creative-toolchain-probe` containing the complete `probe-report.json`, official archive SHA256 log and APT logs (not vendor binaries). Results: **GIMP** `cli_ok` version 2.10.36, **Krita** package version 5.2.2 with startup error `qt.qpa.xcb: could not connect to display`, **MeshLab** package version 2020.09 with same DISPLAY error, **Material Maker** 1.7 archive checksum match and `xvfb-run material_maker.x86_64 --version` exit 0 (reports Godot engine 4.7.stable.official.5b4e0cb0f). The Qt no-DISPLAY errors are *not* missing packages; second run checks Xvfb-assisted startup. Still no proof of successful GUI painting or unattended export. 
