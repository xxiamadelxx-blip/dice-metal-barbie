extends SceneTree
## Safety regression. Run ONLY with an intentionally mismatched PRIVATE_SOURCE.
## Original public procedural art must remain usable. Never load unaudited GLB.
const Art = preload("res://src/dice/m5_original_obsidian_art.gd")
const D20 = preload("res://src/dice/d20_body.gd")
const Ico = preload("res://src/core/icosahedron.gd")
func _initialize() -> void:
    call_deferred("_run")
func _run() -> void:
    ProjectSettings.set_setting(Art.PROJECT_FLAG, true)
    assert(FileAccess.file_exists(Art.PRIVATE_SOURCE))
    var current := FileAccess.get_sha256(Art.PRIVATE_SOURCE)
    assert(current != Art.PRIVATE_SHA256,"BAD_SHA_TEST_REQUIRES_CORRUPTED_COPY_NOT_ORIGINAL")
    var d := D20.new()
    d.freeze=true
    root.add_child(d)
    await process_frame
    assert(not d.m5_original_visual_active,"Wrong source SHA bypassed asset-integrity gate")
    assert(d.get_node_or_null("M5OriginalObsidian500KVisual")==null,"Unverified private material rendered despite SHA mismatch")
    var old := d.get_node_or_null("ObsidianD20") as MeshInstance3D
    assert(old!=null and old.visible,"Fallback original D20 visual missing")
    var collider:=d.get_node_or_null("IcosahedronCollision") as CollisionShape3D
    assert(collider!=null and collider.shape is ConvexPolygonShape3D)
    assert((collider.shape as ConvexPolygonShape3D).points.size()==12)
    for i in range(20):
        d.global_transform=Transform3D(Basis(Quaternion(Ico.face_normal(i),Vector3.UP)),Vector3.ZERO)
        assert(d.top_visible_value()==Ico.numbers()[i],"Disabled art changed the original numbered rules")
    print("M5_HASH_MISMATCH_FAIL_CLOSED PASS invalid_glb_sha=",current," fallback_original=YES 20_values=YES Jolt_hull=YES")
    quit(0)