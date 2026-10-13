extends SceneTree
## Actual Jolt physical D12 simulation. Small-N integration gate only.
const Dodeca = preload("res://src/core/dodecahedron.gd")
const D12 = preload("res://src/dice/d12_body.gd")
const TRIALS := 10
var checks := 0
var failed := 0

func _initialize() -> void:
    call_deferred("_run")

func _expect(ok: bool, detail: String) -> void:
    checks += 1
    if not ok:
        failed += 1
        push_error(detail)

func _run() -> void:
    var scene: Node3D = load("res://src/main.tscn").instantiate()
    root.add_child(scene)
    await process_frame

    var die = D12.new()
    root.add_child(die)
    var collision: CollisionShape3D = die.get_node("DodecahedronCollision")
    _expect(collision.shape is ConvexPolygonShape3D, "D12 requires convex physical collider")
    _expect(collision.shape.points.size() == 20, "D12 collider must have 20 vertices")
    var body: MeshInstance3D = die.get_node("ObsidianD12")
    _expect(body.mesh.get_faces().size() == 108, "12 pentagons triangulate to 36 mesh triangles")
    _expect((die.get_node("ActualSculptedBevels") as MeshInstance3D).mesh.get_faces().size() == 360, "D12 needs five actual bevel shoulder quads per pentagon")
    _expect((die.get_node("FaceInsetBronzeHairlines") as MeshInstance3D).mesh.get_faces().size() == 360, "D12 needs real pentagonal in-face bronze tracery")

    var values := Dodeca.numbers()
    for i in range(12):
        var value: int = values[i]
        var glyph: Label3D = die.numeral_node(value)
        _expect(glyph != null, "Missing D12 glyph %d" % value)
        if glyph != null:
            _expect(glyph.text == str(value), "Face label does not match mapping")
            _expect(glyph.basis.z.dot(Dodeca.face_normal(i)) > 0.999, "Label not attached to outward face")
            _expect(glyph.position.distance_to(Dodeca.face_center(i) + Dodeca.face_normal(i) * 0.0025) < 0.002, "Numeral position doesn't match physical face")
    die.queue_free()
    await process_frame

    var completed := 0
    var freq := PackedInt32Array()
    freq.resize(13)
    for trial in range(TRIALS):
        scene.call("_throw_physical_d12")
        await physics_frame
        var active: RigidBody3D = scene.get_node_or_null("PhysicalD12")
        _expect(active != null, "No physical D12 body")
        if active == null:
            break
        var stopped := false
        for step in range(1150):
            await physics_frame
            if not is_instance_valid(active):
                break
            if not active.rolling:
                stopped = true
                break
        _expect(stopped, "D12 failed to stop")
        if not stopped:
            break
        _expect(active.failure == "", "D12 physical failure: %s" % active.failure)
        _expect(active.edge_recovery_count <= 3, "D12 recovery exceeded budget")
        if active.failure != "":
            break
        var face_value: int = Dodeca.top_value(active.global_transform.basis.orthonormalized())
        _expect(face_value >= 1 and face_value <= 12, "Out-of-bounds D12 number")
        _expect(active.result == face_value, "D12 output differs from upper face")
        _expect(scene.last_result == face_value, "D12 UI differs from upper face")
        _expect(active.sleeping, "Result before Jolt sleep")
        _expect(absf(active.position.x) < 3.1 and absf(active.position.z) < 5.2, "D12 escaped the table")
        _expect(not scene.throw_button.disabled and not scene.selected_chooser.disabled, "D12 input stayed locked")
        if face_value >= 1 and face_value <= 12:
            freq[face_value] += 1
            completed += 1
        await process_frame

    print("M3 D12 Jolt rolls: %d/%d completed, %d checks, %d failures, distribution=%s" % [completed, TRIALS, checks, failed, str(freq)])
    quit(0 if completed == TRIALS and failed == 0 else 1)
