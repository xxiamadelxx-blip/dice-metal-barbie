extends SceneTree
## M3 genuine D20 Jolt simulation and face-number verification.
## Small smoke series, not a statistically powered physical fairness study.

const Ico = preload("res://src/core/icosahedron.gd")
const D20 = preload("res://src/dice/d20_body.gd")
const TRIALS := 8
var checks := 0
var failures := 0

func _initialize() -> void:
    call_deferred("_run")

func _check(value: bool, message: String) -> void:
    checks += 1
    if not value:
        failures += 1
        push_error(message)

func _run() -> void:
    var scene: Node3D = load("res://src/main.tscn").instantiate()
    root.add_child(scene)
    await process_frame

    var die = D20.new()
    root.add_child(die)
    var shape: CollisionShape3D = die.get_node("IcosahedronCollision")
    _check(shape.shape is ConvexPolygonShape3D, "D20 requires convex polyhedron collider")
    _check(shape.shape.points.size() == 12, "D20 collision must use 12 golden-ratio vertices")

    var visual: MeshInstance3D = die.get_node("ObsidianD20")
    _check(visual.mesh.get_faces().size() == 60, "D20 mesh must have 20 triangles = 60 vertices")
    var numbers := Ico.numbers()
    for face_id in range(20):
        var face: int = numbers[face_id]
        var label: Label3D = die.numeral_node(face)
        _check(label != null, "D20 missing face label %d" % face)
        if label != null:
            _check(label.text == str(face), "D20 label text mismatch")
            _check(label.basis.z.dot(Ico.face_normal(face_id)) > 0.999, "Label must face outward")
    die.queue_free()
    await process_frame

    var completed := 0
    var frequency := PackedInt32Array()
    frequency.resize(21)
    for trial in range(TRIALS):
        scene.call("_throw_physical_d20")
        await physics_frame
        var active: RigidBody3D = scene.get_node_or_null("PhysicalD20")
        _check(active != null, "No physical D20 on trial %d" % trial)
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
        _check(finished, "D20 failed to finish within budget on trial %d" % trial)
        if not finished:
            break
        _check(active.failure == "", "D20 failed: %s" % active.failure)
        _check(active.edge_recovery_count <= 3, "D20 physical recovery exceeded budget")
        if active.failure != "":
            break
        var top: int = Ico.top_value(active.global_transform.basis.orthonormalized(), 0.02)
        _check(active.result == top, "D20 output must equal upper numbered face")
        _check(scene.last_result == top, "UI result must equal physical upper face")
        _check(active.sleeping, "D20 should settle naturally")
        _check(top >= 1 and top <= 20, "D20 range 1..20")
        _check(absf(active.position.x) < 3.1 and absf(active.position.z) < 5.2, "D20 must stay on table")
        _check(scene.throw_button.disabled == false, "D20 roll control must unlock")
        if top >= 1 and top <= 20:
            frequency[top] += 1
            completed += 1
        await process_frame
    print("M3 numbered D20 physical: %d/%d, %d checks, %d fail, values=%s" % [completed, TRIALS, checks, failures, str(frequency)])
    quit(0 if failures == 0 and completed == TRIALS else 1)
