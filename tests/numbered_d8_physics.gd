extends SceneTree
## Real Jolt throws, not 3D snapshots or fake results; small smoke only.
const Octa = preload("res://src/core/octahedron.gd")
const D8 = preload("res://src/dice/d8_body.gd")
const TRIALS := 12
var checks := 0
var failures := 0

func _initialize() -> void:
    call_deferred("_run")

func _expect(ok: bool, message: String) -> void:
    checks += 1
    if not ok:
        failures += 1
        push_error(message)

func _run() -> void:
    var instance: Node3D = load("res://src/main.tscn").instantiate()
    root.add_child(instance)
    await process_frame
    var die = D8.new()
    root.add_child(die)
    var collision: CollisionShape3D = die.get_node("OctahedronCollision")
    _expect(collision.shape is ConvexPolygonShape3D, "D8 requires a real convex collision hull")
    _expect(collision.shape.points.size() == 6, "D8 hull needs six vertices")
    var visual: MeshInstance3D = die.get_node("ObsidianD8")
    _expect(visual.mesh.get_faces().size() == 24, "D8 must render exactly eight triangles")
    var numbers := Octa.numbers()
    for face_id in range(8):
        var number: int = numbers[face_id]
        var glyph: Label3D = die.numeral_node(number)
        _expect(glyph != null, "D8 missing face glyph %d" % number)
        if glyph != null:
            _expect(glyph.text == str(number), "Incorrect face numeral")
            _expect(glyph.basis.z.dot(Octa.face_normal(face_id)) > 0.999, "Glyph plane not attached to actual face")
            _expect(glyph.position.distance_to(Octa.face_center(face_id) + Octa.face_normal(face_id) * 0.0025) < 0.002, "Glyph not positioned on face")
    die.queue_free()
    await process_frame

    var completed := 0
    var frequencies := PackedInt32Array()
    frequencies.resize(9)
    for trial in range(TRIALS):
        instance.call("_throw_physical_d8")
        await physics_frame
        var active: RigidBody3D = instance.get_node_or_null("PhysicalD8")
        _expect(active != null, "No D8 physical body")
        if active == null:
            break
        var settled := false
        for step in range(1150):
            await physics_frame
            if not is_instance_valid(active):
                break
            if not active.rolling:
                settled = true
                break
        _expect(settled, "D8 never completed its physical throw")
        if not settled:
            break
        _expect(active.failure == "", "D8 invalid result: %s" % active.failure)
        _expect(active.edge_recovery_count <= 3, "Too many physical edge recoveries")
        if active.failure != "":
            break
        var value: int = Octa.top_value(active.global_transform.basis.orthonormalized())
        _expect(value >= 1 and value <= 8, "D8 outside numeric range")
        _expect(active.result == value, "Outcome differs from physical top face")
        _expect(instance.last_result == value, "Displayed result differs from visible face")
        _expect(active.sleeping, "D8 must reach a physical sleep state")
        _expect(absf(active.position.x) < 3.1 and absf(active.position.z) < 5.2, "D8 left table")
        _expect(instance.throw_button.disabled == false, "Throw button remained locked")
        _expect(instance.selected_chooser.disabled == false, "Chooser remained locked")
        if value >= 1 and value <= 8:
            frequencies[value] += 1
            completed += 1
        await process_frame

    print("M3 D8 Jolt throws: %d/%d complete, %d checks, %d failures, frequencies=%s" % [completed, TRIALS, checks, failures, str(frequencies)])
    quit(0 if failures == 0 and completed == TRIALS else 1)
