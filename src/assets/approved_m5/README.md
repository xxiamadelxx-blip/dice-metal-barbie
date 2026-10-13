# User-selected first obsidian D20

This is an optional private build input. Keep the licensed binaries outside public git.
Restore the original selected files from private proof package
`libfile_b0ab446a69a48191ba390f2a2964d6e7`, then copy:

| Package file | Runtime filename | SHA256 |
| --- | --- | --- |
| `work/selected-obsidian-d20.glb` | `d20_selected_obsidian.glb` | `4c04c1707e1ed0d59f5bee286525059d85cdec5668c2ce5969d968d3a18221df` |
| `work/studio.hdr` | `selected_studio.hdr` | `a816625569d497e3672d522357c8ae292b9ef947eb3ae1c80c00e33f76b6a971` |

The user chose the first/left reference. Do not substitute the later brighter
gold GLB (`38e16da7…`) or later HDR. Preserve imported materials without overrides.
Stone: diaverx miky Procedural Obsidian, free royalty-free BlenderKit asset,
base id `92e31cbc-5b4e-4ead-a966-84bf106808c3`. Original metadata, Blender source,
baked maps and provenance remain in the private source proof package.

Import the project with Godot 4.6.3 after copying. Keep `.blend` authoring sources
outside the runtime project to avoid Godot's Blender-path import prompt.
Run `godot --headless --editor --path . --import`, then
`godot --headless --path . --script res://tests/engraved_assets.gd`.
Graphical end-to-end capture:
`godot --path . --rendering-method mobile --audio-driver Dummy --script res://tests/m5_selected_obsidian_runtime.gd --write-movie build/approved-runtime-proof/game-first-obsidian.avi --fixed-fps 24`.

The latter exits 2 with NOT_VERIFIED if private inputs are missing. Ordinary
public CI exercises fallback assets, so its green status cannot certify this
selected material. Raw hashes are checked while source files exist; exported
Godot packs remap imported resources. Android inclusion and appearance require
a separate export and device check with these exact private inputs.
