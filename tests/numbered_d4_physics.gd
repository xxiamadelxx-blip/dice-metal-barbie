extends SceneTree
## D4 Jolt integration. 12 face glyphs, actual apex value, no numerical snapping.
const Tetra = preload("res://src/core/tetrahedron.gd")
const D4 = preload("res://src/dice/d4_body.gd")
const TRIALS := 12
var checks := 0
var failures := 0

func _initialize() -> void:
    call_deferred("_run")

func _assert(ok: bool, message: String) -> void:
    checks += 1
    if not ok:
        failures += 1
        push_error(message)

func _run() -> void:
    var scene: Node3D = load("res://src/main.tscn").instantiate()
    root.add_child(scene)
    await process_frame
    var showroom: Node3D = scene.get_node("IdleDiceDisplay")
    _assert(showroom.get_child_count() == 4, "Approved idle composition must show exactly four real 3D dice")
    for prop in showroom.get_children():
        var nonrolling: RigidBody3D = prop as RigidBody3D
        _assert(nonrolling != null and nonrolling.freeze, "Idle prop must be stationary")
        if nonrolling != null:
            _assert(nonrolling.collision_layer == 0 and nonrolling.collision_mask == 0, "Idle prop must NEVER affect Jolt randomness")
    _assert(scene.selected_chooser.get_selected_id() == scene.selected_die, "Initial chooser must match selected die")
    _assert(scene.throw_button.tooltip_text == "Бросить D6", "D6 must be the initial selected throw")
    _assert(scene.selected_chooser.get_item_count() == 5, "D4 D6 D8 D12 D20 all selectable")
    var die = D4.new()
    root.add_child(die)

    var collider: CollisionShape3D = die.get_node("TetrahedronCollision")
    _assert(collider.shape is ConvexPolygonShape3D, "D4 requires physical convex hull")
    _assert(collider.shape.points.size() == 4, "D4 collision needs four vertices")
    var mesh: MeshInstance3D = die.get_node("ObsidianD4")
    _assert(mesh.mesh.get_faces().size() == 12, "D4 visible mesh has four triangles")
    _assert((die.get_node("ActualSculptedBevels") as MeshInstance3D).mesh.get_faces().size() == 72, "D4 must have real beveled geometry")
    _assert((die.get_node("FaceInsetBronzeHairlines") as MeshInstance3D).mesh.get_faces().size() == 72, "D4 bronze is inlaid into face planes")
    var num_glyphs := 0
    for apex in range(4):
        for opposite in range(4):
            if apex == opposite:
                continue
            var label: Label3D = die.glyph(apex + 1, opposite)
            _assert(label != null, "Missing apex %d on face %d" % [apex + 1, opposite])
            if label == null:
                continue
            num_glyphs += 1
            _assert(label.text == str(apex + 1), "D4 glyph must repeat APEX number on each adjacent face")
            _assert(label.basis.z.dot(Tetra.face_normal(opposite)) > 0.999, "Printed numeral must face away from body")
            _assert(label.position.distance_to(Tetra.printed_position(apex, opposite)) < 0.001, "Glyph is not on physical triangle")
    _assert(num_glyphs == 12, "Each apex must have three printed glyphs")

    die.queue_free()
    await process_frame
    var complete := 0
    var counts := PackedInt32Array()
    counts.resize(5)
    for trial in range(TRIALS):
        scene.call("_throw_physical_d4")
        _assert(scene.idle_display == null, "Real throw must clear the decorative display")
        await physics_frame
        var active: RigidBody3D = scene.get_node_or_null("PhysicalD4")
        _assert(active != null, "No actual D4 body in scene")
        if active == null:
            break
        var finished := false
        for tick in range(1150):
            await physics_frame
            if not is_instance_valid(active):
                break
            if not active.rolling:
                finished = true
                break
        _assert(finished, "D4 physical body never finished")
        if not finished:
            break
        _assert(active.failure == "", "D4 physical failure: %s" % active.failure)
        _assert(active.edge_recovery_count <= 3, "D4 edge recovery exceeded budget")
        if active.failure != "":
            break
        var value := Tetra.top_value(active.global_transform.basis.orthonormalized())
        _assert(value >= 1 and value <= 4, "D4 output outside 1..4")
        _assert(active.result == value, "D4 result does not match top vertex")
        _assert(scene.last_result == value, "D4 UI result does not match top apex")
        _assert(active.sleeping, "D4 resulted while still moving")
        _assert(absf(active.position.x) < 3.1 and absf(active.position.z) < 5.2, "D4 escaped tabletop")
        _assert(not scene.throw_button.disabled and not scene.selected_chooser.disabled, "Controls never unlocked")
        if value >= 1 and value <= 4:
            complete += 1
            counts[value] += 1
        await process_frame
    print("M3 D4 Jolt rolls: %d/%d completed, %d checks, %d failed, values=%s" % [complete, TRIALS, checks, failures, str(counts)])
    quit(0 if failures == 0 and complete == TRIALS else 1)
