extends SceneTree
## Fast M3 regression for deferred SceneTree removal of a 2xD10 parent.
## Test the actual game actions/Jolt bodies, never fabricated die values.
const Shape = preload("res://src/core/trapezohedron.gd")
const Rules = preload("res://src/core/dice_rules.gd")
var errors := 0
var checks := 0
func _initialize() -> void:
    call_deferred("_run")
func _check(ok: bool, why: String) -> void:
    checks += 1
    if not ok:
        errors += 1
        push_error(why)
func _wait(dice: Array[RigidBody3D]) -> bool:
    for tick in range(1800):
        await physics_frame
        var still := false
        for die in dice:
            if not is_instance_valid(die) or bool(die.get("rolling")):
                still = true
        if not still:
            return true
    return false
func _run() -> void:
    var packed: PackedScene = load("res://src/main.tscn")
    var scene := packed.instantiate() as Node3D
    root.add_child(scene)
    await process_frame
    for trial in range(3):
        scene.call("_throw_percentile_d100")
        await physics_frame
        var current := scene.get("active_percentile") as Node3D
        var parent := scene.get_node_or_null("PhysicalD100Percentile") as Node3D
        _check(current != null and parent == current,
            "D100_PAIR trial %d found stale parent after reuse" % trial)
        var matching := 0
        for child in scene.get_children():
            if child.name.begins_with("PhysicalD100Percentile"):
                matching += 1
        _check(matching == 1, "D100_PAIR trial %d retained %d colliding pair parents" %
            [trial,matching])
        if current == null or parent != current:
            break
        var tens := parent.get_node_or_null("TensD10") as RigidBody3D
        var ones := parent.get_node_or_null("OnesD10") as RigidBody3D
        _check(tens != null and ones != null and tens != ones,
            "D100_PAIR trial %d requires two distinct real D10 bodies" % trial)
        if tens == null or ones == null:
            break
        _check(tens.get_parent() == parent and ones.get_parent() == parent,
            "D100_PAIR trial %d has detached body" % trial)
        var complete := await _wait([tens,ones])
        _check(complete,"D100_PAIR trial %d not completed physically" % trial)
        if not complete:
            break
        var a: int = Shape.top_value(10,tens.global_transform.basis.orthonormalized())
        var b: int = Shape.top_value(10,ones.global_transform.basis.orthonormalized())
        var expected: int = Rules.percentile((a%10)*10,b%10)
        _check(a == int(tens.get("result")) and b == int(ones.get("result")) and
            a >= 1 and b >= 1 and expected == int(scene.get("last_result")),
            "D100_PAIR trial %d result differs from physical upper faces" % trial)
        _check(tens.sleeping and ones.sleeping,
            "D100_PAIR trial %d not physically settled" % trial)
        await process_frame
    if errors == 0:
        scene.call("_throw_physical_d10")
        await physics_frame
        _check(scene.get_node_or_null("PhysicalD100Percentile") == null,
            "D100_PAIR parent remained live after switching to D10")
        var lone := scene.get_node_or_null("PhysicalD10") as RigidBody3D
        _check(lone != null,"Switch from pair did not spawn genuine D10")
        if lone != null:
            var done := await _wait([lone])
            _check(done and str(lone.get("failure")) == "",
                "D10 following D100_PAIR failed physics")
            if done and str(lone.get("failure")) == "":
                var value: int = Shape.top_value(10,
                    lone.global_transform.basis.orthonormalized())
                _check(value == int(lone.get("result")) and
                    value == int(scene.get("last_result")),
                    "D10 following pair misreports actual upper face")
    print("M3_FAST_PAIR_LIFECYCLE checks=%d failures=%d" % [checks,errors])
    quit(0 if errors == 0 else 1)
