extends SceneTree
## A real rolling test, NOT statistical fairness proof or a model preview.
const ShapeMath = preload("res://src/core/trapezohedron.gd")
const Rules = preload("res://src/core/dice_rules.gd")
var checks := 0
var failures := 0

func _initialize() -> void:
    call_deferred("_run")

func _check(ok: bool, reason: String) -> void:
    checks += 1
    if not ok:
        failures += 1
        push_error(reason)

func _wait_for_dice(dice: Array, limit: int) -> bool:
    for step in range(limit):
        await physics_frame
        var done := true
        for die in dice:
            if not is_instance_valid(die) or die.get("rolling"):
                done = false
        if done:
            return true
    return false

func _run() -> void:
    var scene: Node3D = load("res://src/main.tscn").instantiate()
    root.add_child(scene)
    await process_frame
    for sides in [10, 100]:
        if sides == 10:
            scene.call("_throw_physical_d10")
        else:
            scene.call("_throw_physical_d100")
        await physics_frame
        var die: RigidBody3D = scene.get_node_or_null("PhysicalD%d" % sides)
        _check(die != null, "D%d has no physical body" % sides)
        if die == null:
            break
        var collision := die.get_node("TrapezohedronCollision") as CollisionShape3D
        _check(collision.shape is ConvexPolygonShape3D, "D%d convex Jolt hull missing" % sides)
        _check((collision.shape as ConvexPolygonShape3D).points.size() == sides + 2, "D%d wrong convex vertex count" % sides)
        _check(die.call("numeral_node", 1) != null and die.call("numeral_node", sides) != null,
            "D%d missing smallest/largest real attached glyph" % sides)
        var done := await _wait_for_dice([die], 2500)
        _check(done, "D%d never completed a physical throw" % sides)
        if not done:
            break
        _check(die.get("failure") == "", "D%d physical failure: %s" % [sides,die.get("failure")])
        if die.get("failure") != "":
            break
        var top := ShapeMath.top_value(sides, die.global_transform.basis.orthonormalized())
        _check(top == die.get("result"), "D%d result differs from actual upper face" % sides)
        _check(scene.last_result == top, "D%d HUD differs from physically visible face" % sides)
        _check(die.sleeping, "D%d not physically asleep" % sides)
        _check(top >= 1 and top <= sides, "D%d result outside range" % sides)
    # Two physically independent dice. Neither digit may be invented.
    if scene.throw_button.disabled == false:
        scene.call("_throw_percentile_d100")
        await physics_frame
        var pair := scene.get_node_or_null("PhysicalD100Percentile") as Node3D
        _check(pair != null, "D100 pair container missing")
        if pair != null:
            var tens = pair.get_node_or_null("TensD10")
            var ones = pair.get_node_or_null("OnesD10")
            _check(tens != null and ones != null, "D100 needs two separate bodies")
            if tens != null and ones != null:
                var done := await _wait_for_dice([tens,ones], 2500)
                _check(done, "Two percentile Jolt bodies did not settle")
                if done:
                    _check(tens.get("failure") == "" and ones.get("failure") == "", "Failed percentile physical rolls")
                    var tval := ShapeMath.top_value(10,tens.global_transform.basis.orthonormalized())
                    var oval := ShapeMath.top_value(10,ones.global_transform.basis.orthonormalized())
                    _check(tval == tens.get("result") and oval == ones.get("result"), "Percentile digits differ from actual faces")
                    var value := Rules.percentile((tval % 10) * 10, oval % 10)
                    _check(scene.last_result == value, "D100 pair result not computed from its two visible faces")
                    _check(value >= 1 and value <= 100, "Invalid percentile result")
                    _check(scene.throw_button.disabled == false, "D100 pair did not unlock UI")
    print("M3 D10 / D100 physical Jolt: %d checks, %d failures" % [checks,failures])
    quit(0 if failures == 0 else 1)
