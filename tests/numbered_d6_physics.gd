extends SceneTree
## M3 end-to-end physically labeled D6: real Jolt rigid body and visual numerals.
## No snapping, artificial outcome insertion or prerecorded animation.
const Dice = preload("res://src/dice/d6_body.gd")
const Symmetry = preload("res://src/core/cube_symmetry.gd")
const TRIALS := 12
var failures := 0
var checks := 0

func _initialize() -> void:
    call_deferred("_run")

func _expect(condition: bool, context: String) -> void:
    checks += 1
    if not condition:
        failures += 1
        push_error(context)

func _run() -> void:
    var packed: PackedScene = load("res://src/main.tscn")
    _expect(packed != null, "Main scene must load")
    if packed == null:
        quit(1)
        return
    var scene: Node3D = packed.instantiate()
    root.add_child(scene)
    await process_frame
    var camera: Camera3D = scene.get_node("FixedOverheadCamera")
    _expect(camera.projection == Camera3D.PROJECTION_ORTHOGONAL, "Camera must be orthographic")
    _expect(camera.rotation_degrees.distance_to(Vector3(-90, 0, 0)) < 0.01, "Camera must remain top-down")

    for face in range(1, 7):
        var temp = Dice.new()
        root.add_child(temp)
        var label: Label3D = temp.numeral_node(face)
        _expect(label != null, "Missing 3D numeral face %d" % face)
        if label != null:
            _expect(label.text == str(face), "Numeral text mismatch %d" % face)
            var idx := Symmetry.D6_FACE_VALUES.find(face)
            var n: Vector3 = Symmetry.D6_FACE_NORMALS[idx]
            _expect(label.basis.z.dot(n) > 0.999, "Face number %d plane not aligned with physical normal" % face)
            _expect(label.position.distance_to(n * (Dice.SIDE * 0.5 + 0.0025)) < 0.002, "Number %d not physically attached to face" % face)
        temp.queue_free()
        await process_frame

    var frequencies := [0, 0, 0, 0, 0, 0]
    var completed := 0
    for trial in range(TRIALS):
        scene.call("_throw_physical_d6")
        await physics_frame
        var die: RigidBody3D = scene.get_node_or_null("PhysicalD6")
        _expect(die != null, "Trial %d spawned no rigid body" % trial)
        if die == null:
            break
        var settled := false
        for tick in range(1100):
            await physics_frame
            if not is_instance_valid(die):
                break
            if not die.rolling:
                settled = true
                break
        _expect(settled, "Trial %d did not finish within simulation budget" % trial)
        if not settled:
            break
        _expect(die.failure == "", "Trial %d failed: %s" % [trial, die.failure])
        _expect(die.edge_recovery_count <= 3, "Trial %d exceeded physical recovery budget" % trial)
        if die.failure != "":
            break
        var visual := Symmetry.top_value(die.global_transform.basis.orthonormalized(), 0.02)
        _expect(die.result == visual, "Trial %d value != physical upper face (%d vs %d)" % [trial, die.result, visual])
        _expect(scene.last_result == visual, "Trial %d UI result != upper face" % trial)
        _expect(die.sleeping, "Trial %d outcome emitted while cube still moving" % trial)
        _expect(absf(die.position.x) < 3.1 and absf(die.position.z) < 5.2, "Trial %d left table" % trial)
        _expect(scene.throw_button.disabled == false, "Trial %d button remained locked" % trial)
        if die.result >= 1 and die.result <= 6:
            frequencies[die.result - 1] += 1
            completed += 1
        await process_frame

    print("M3 numbered D6 physical trials: %d/%d complete, %d checks, %d FAIL; counts=%s" % [completed, TRIALS, checks, failures, str(frequencies)])
    quit(0 if failures == 0 and completed == TRIALS else 1)
