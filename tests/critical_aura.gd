extends SceneTree
## Assert critical visuals respect physical outcome and never alter the solver.
const Aura = preload("res://src/visual/critical_aura.gd")
var checks := 0
var failures := 0

func check(ok: bool, message: String) -> void:
    checks += 1
    if not ok:
        failures += 1
        push_error(message)

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    var die := RigidBody3D.new()
    die.name = "RealPhysicalD20"
    die.mass = 1.1
    var collision := CollisionShape3D.new()
    collision.name = "UnmodifiedPhysicalHull"
    collision.shape = SphereShape3D.new()
    die.add_child(collision)
    root.add_child(die)
    await process_frame
    var original := collision.shape
    check(Aura.spawn(die, 6, 20) == null, "Non-D20 cannot flash even on 20")
    check(Aura.spawn(die, 20, 2) == null, "Noncritical 2 cannot flash")
    check(Aura.spawn(die, 20, 19) == null, "Noncritical 19 cannot flash")
    check(die.get_node_or_null("CriticalDiceAura") == null, "No decoration before a genuine crit")
    var failure := Aura.spawn(die, 20, 1)
    check(failure != null, "D20 1 must trigger a crimson 3D pulse")
    if failure != null:
        check(failure.get_node_or_null("CrimsonPulse") != null, "Crimson torus geometry missing")
        check(failure.get_node_or_null("CrimsonEmber_0") is MeshInstance3D,
            "Nat1 needs die-origin crimson contact embers, not gold success sparks")
        check(failure.get_node_or_null("GoldSpark_0") == null,
            "Natural 1 failure must never receive victory sparks")
        check(failure.get_node_or_null("DieOriginFlash") is OmniLight3D, "Die-origin flash missing")
        check(Aura.spawn(die, 20, 20) == failure, "Concurrent duplicate auras forbidden")
        check(failure.global_position.distance_to(die.global_position + Vector3(0, 0.55, 0)) < 0.001,
            "Shockwave must originate at die, not HUD")
        for child in failure.get_children():
            check(not child is CollisionObject3D and not child is CollisionShape3D, "Critical decoration must not collide")
    check(is_equal_approx(die.mass, 1.1) and collision.shape == original, "Critical effect cannot touch Jolt body")
    await create_timer(1.1).timeout
    check(die.get_node_or_null("CriticalDiceAura") == null, "Transient aura must clean itself up")
    var success := Aura.spawn(die, 20, 20)
    check(success != null and success.get_node_or_null("GoldPulse") != null,
        "Natural D20 20 must trigger a golden 3D pulse")
    if success != null:
        check(success.get_node_or_null("GoldSpark_0") is MeshInstance3D,
            "Nat20 success needs actual die-origin ascending gold sparks")
        check(success.get_node_or_null("CrimsonEmber_0") == null,
            "Natural 20 success cannot receive failure embers")
        for item in success.get_children():
            check(not item is CollisionObject3D and not item is CollisionShape3D,
                "Gold effect must not change Jolt contacts")
    die.queue_free()
    await process_frame
    print("M5 critical D20 3D aura: %d checks, %d FAIL" % [checks, failures])
    quit(0 if failures == 0 else 1)
