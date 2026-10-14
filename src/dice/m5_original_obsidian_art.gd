extends RefCounted
## M5 experimental, explicit opt-in. LICENSED D20 source is PRIVATE, never Git.
## This adapter changes VISUAL ART ONLY and maps the actually printed 1..20
## back to the original Jolt geometric top-face solver without outcome snapping.
##
## Verified genuine source:
## BlenderKit Procedural Obsidian, diaverx miky. Packed GLB MUST match SHA.
## Master: exactly 500,000 glTF indexed triangles, 20 separate gold numbers.
const PRIVATE_SOURCE := "res://src/assets/private/d20_selected_original_500k.glb"
const PRIVATE_SHA256 := "60a7d624c126776eb357fb0ba97c8724175a5ec7ce629358276286da75889f39"
const PROJECT_FLAG := "dice/m5/use_private_d20"
const EXPECTED_GOLD := 20
const EXPECTED_STONE_TRIANGLES := 220000
const EXPECTED_GOLD_TRIANGLES := 280000

# Calculated by matching actual GLB gold mesh face directions to
# src/core/icosahedron.gd::face_normal (proper 3D rigid rotation).
# Face ordering is 0-based Ico.FACES, value is 1-based number engraved in GLB.
# The unmodified fallback numbering is different, so it MUST NOT be reused
# when this exact premium model is visible on the real Jolt body.
const PRINTED_FACE_VALUES := [
    6, 1, 5, 10, 13, 2, 12, 18, 14, 4,
    11, 16, 20, 15, 8, 7, 17, 19, 9, 3
]

# Column vectors of the correct SO(3) transform: Godot GLB local -> canonical
# Ico model coordinates. Calibrated from 20 actual Gold_XX mesh face centers
# with an optimal proper rotation (mean 2.27°, maximum 3.36° due glyph offsets).
# No mirroring: det = +1. This transform is VISUAL ONLY.
const VISUAL_ROTATION := Basis(
    Vector3(-0.99980195, -0.00372885, 0.01954887),
    Vector3(-0.00363344, -0.93157876, -0.36352142),
    Vector3(0.01956683, -0.36352045, 0.93138071)
)
# Canonical Jolt hull circumradius 0.88; GLB maximal extent ~0.975.
# At .895 visible metal/stone stays within the original physical envelope.
const VISUAL_SCALE := 0.895

static var _validated_scene: PackedScene = null
static var _verification_attempted := false

static func enabled() -> bool:
    return bool(ProjectSettings.get_setting(PROJECT_FLAG, false))

static func printed_value_for_face(face_index: int) -> int:
    if face_index < 0 or face_index >= PRINTED_FACE_VALUES.size():
        return -1
    return int(PRINTED_FACE_VALUES[face_index])

static func _count_model(node: Node, counters: Dictionary) -> void:
    if node is MeshInstance3D:
        var piece := node as MeshInstance3D
        if piece.mesh == null:
            return
        var triangles := 0
        for i in range(piece.mesh.get_surface_count()):
            var indices: int = piece.mesh.surface_get_array_index_len(i)
            var verts: int = piece.mesh.surface_get_array_len(i)
            var count := indices if indices > 0 else verts
            if count % 3 != 0:
                counters["bad"] = true
            triangles += count / 3
        if str(piece.name).begins_with("Gold_"):
            counters["gold"] += 1
            counters["gold_tris"] += triangles
        elif str(piece.name).begins_with("D20_Engraved"):
            counters["stone"] += 1
            counters["stone_tris"] += triangles
        else:
            counters["bad"] = true
        counters["meshes"] += 1
    for child in node.get_children():
        _count_model(child, counters)

static func _scene_checked() -> PackedScene:
    if not enabled():
        return null
    if _verification_attempted:
        return _validated_scene
    _verification_attempted = true
    if not FileAccess.file_exists(PRIVATE_SOURCE):
        push_warning("M5 licensed D20 source missing. Using original Jolt D20 visual.")
        return null
    var digest := FileAccess.get_sha256(PRIVATE_SOURCE)
    if digest != PRIVATE_SHA256:
        push_warning("M5 private D20 hash does not match known good 500k asset. Fallback.")
        return null
    if not ResourceLoader.exists(PRIVATE_SOURCE):
        push_warning("M5 private D20 source is not imported by Godot. Fallback.")
        return null
    var packed := load(PRIVATE_SOURCE) as PackedScene
    if packed == null:
        push_warning("M5 private D20 GLB failed scene import. Fallback.")
        return null
    var temporary := packed.instantiate()
    var totals := {"gold":0,"gold_tris":0,"stone":0,"stone_tris":0,"meshes":0,"bad":false}
    _count_model(temporary,totals)
    temporary.free()
    if bool(totals["bad"]) or int(totals["gold"]) != EXPECTED_GOLD or int(totals["stone_tris"]) != EXPECTED_STONE_TRIANGLES or int(totals["gold_tris"]) != EXPECTED_GOLD_TRIANGLES:
        push_warning("M5 private 500k GLB mesh contract failed. Fallback: "+str(totals))
        return null
    if absf(VISUAL_ROTATION.determinant() - 1.0) > .001:
        push_warning("M5 visual orientation is not a proper rotation. Fallback.")
        return null
    var labels := {}
    for value in PRINTED_FACE_VALUES:
        if int(value) < 1 or int(value) > 20 or labels.has(int(value)):
            push_warning("M5 face label mapping not bijective. Fallback.")
            return null
        labels[int(value)] = true
    _validated_scene = packed
    print("DICE_M5_REAL_PRIVATE_OBSIDIAN_VERIFIED source_sha=", digest,
          " mesh=",totals["meshes"]," stone_tris=",totals["stone_tris"],
          " gold_tris=",totals["gold_tris"]," values=",PRINTED_FACE_VALUES)
    return _validated_scene

static func make_visual() -> Node3D:
    var packed := _scene_checked()
    if packed == null:
        return null
    var instance := packed.instantiate() as Node3D
    if instance == null:
        return null
    instance.name = "M5OriginalObsidian500KVisual"
    instance.basis = VISUAL_ROTATION
    instance.scale = Vector3.ONE * VISUAL_SCALE
    return instance
