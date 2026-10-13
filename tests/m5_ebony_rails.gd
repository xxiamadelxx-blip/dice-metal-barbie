extends SceneTree
## Four VISUAL polished ebony bevels, unchanged collision shape boxes.
const BeveledBox = preload("res://src/visual/beveled_box.gd")
var failures := 0
var checks := 0
func _initialize() -> void:
    call_deferred("_run")
func _check(c: bool,message: String) -> void:
    checks += 1
    if not c:
        failures += 1
        push_error(message)
func _run() -> void:
    var scene := load("res://src/main.tscn").instantiate() as Node3D
    root.add_child(scene)
    await process_frame
    for rail_name in ["RailLeft","RailRight","RailTop","RailBottom"]:
        var rail := scene.get_node_or_null(rail_name) as StaticBody3D
        _check(rail != null,"Missing original physical rail "+rail_name)
        if rail == null:
            continue
        var collider := rail.get_node_or_null("CollisionShape3D") as CollisionShape3D
        _check(collider != null and collider.shape is BoxShape3D,
            "Premium visual must NOT replace the rail BoxShape/Jolt")
        var mesh := rail.get_node_or_null("StaticBoxVisual") as MeshInstance3D
        _check(mesh != null,"Ebony rail visual missing")
        if mesh != null:
            _check(mesh.mesh is ArrayMesh,"Rail must use authored chamfered mesh, not a square slab")
            _check(mesh.mesh.get_surface_count()==1,"Rail bevel must be one efficient material draw call")
            var mat := mesh.material_override as StandardMaterial3D
            _check(mat != null and mat.clearcoat_enabled,
                "Ebony lacquer requires real reflective PBR material")
    # PBR studio cards must actually REACH the real D20 material.
    for light_name in ["StudioCardWarm","StudioCardCool"]:
        var light := scene.get_node_or_null(light_name) as OmniLight3D
        _check(light != null,"Missing real studio light "+light_name)
        if light != null:
            var preview := scene.get_node_or_null("IdleDiceDisplay/PreviewD20") as RigidBody3D
            _check(preview != null and light.global_position.distance_to(
                    preview.global_position)<light.omni_range,
                "Light falls outside actual D20 reflection radius: "+light_name)
    var d4_card := scene.get_node_or_null("StudioCardD4") as OmniLight3D
    var d4_preview := scene.get_node_or_null("IdleDiceDisplay/PreviewD4") as RigidBody3D
    _check(d4_card != null and d4_preview != null,
        "Actual D4 side-light or original physical showcase missing")
    if d4_card != null and d4_preview != null:
        _check(d4_card.global_position.distance_to(d4_preview.global_position)
            < d4_card.omni_range, "D4 side key physically cannot light its real visual mesh")
        _check(d4_card.light_energy > 0.9, "D4 side material must have a visible real bounce")
    var unique := BeveledBox.create(Vector3(0.35,0.9,10.8),0.052)
    _check(unique != null and unique.get_surface_count()==1,
        "Bevel factory did not generate valid single-surface rail mesh")
    print("M5_EBONY_RAILS checks=%d failures=%d" % [checks,failures])
    scene.queue_free()
    quit(0 if failures==0 else 1)
