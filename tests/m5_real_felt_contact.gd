extends SceneTree
## A real Jolt D6 must touch the unchanged StaticBody floor before visible
## velvet animation. Idle showcase/rails/other bodies alone cannot cause it.
var checks := 0
var failures := 0

func _initialize() -> void:
    call_deferred("_run")

func _check(condition: bool, detail: String) -> void:
    checks += 1
    if not condition:
        failures += 1
        push_error(detail)

func _run() -> void:
    var scene := load("res://src/main.tscn").instantiate() as Node3D
    root.add_child(scene)
    await process_frame
    await process_frame
    var floor := scene.get_node_or_null("VelvetTable") as StaticBody3D
    var skin := scene.get_node_or_null("M5VelvetContactSurface") as Node3D
    _check(floor != null and skin != null, "Real static Jolt floor or felt skin missing")
    if floor == null or skin == null:
        quit(1)
        return
    var collision := floor.get_node_or_null("CollisionShape3D") as CollisionShape3D
    var original_shape: Shape3D = collision.shape if collision != null else null
    _check(original_shape is BoxShape3D,"True unchanged Jolt floor collider required")
    var painted_base := floor.get_node_or_null("StaticBoxVisual") as MeshInstance3D
    _check(painted_base != null and is_equal_approx(painted_base.position.y,-0.012),
        "Separately named visual box must not cover the actual textile shader skin")
    _check(int(skin.get("impact_count")) == 0 and not bool(skin.get("active")),
        "Idle launch screen must not animate felt")
    _check(skin.get_node_or_null("VisualOnlyTessellatedFelt") is MeshInstance3D,
        "Felt vertex displacement mesh missing")
    _check(not bool(skin.call("register_impact",Vector3.ZERO,0.0,0.04)),
        "Zero-speed contact must not animate table")
    _check(int(skin.get("impact_count")) == 0, "No-impact condition changed animation count")
    scene.call("_throw_physical_d6")
    var impacted := false
    for tick in range(700):
        await physics_frame
        if int(skin.get("impact_count")) > 0:
            impacted = true
            break
    _check(impacted,"Actual Jolt falling D6 never emitted floor contact")
    _check(floor.get_node("CollisionShape3D").shape == original_shape,
        "Table reaction modified a Jolt collision shape")
    if impacted:
        var point: Vector3 = skin.get("last_impact_world")
        _check(absf(point.x) <= 3.3 and absf(point.z) <= 5.3,
            "Real impact point not located on the physical table")
        _check(float(skin.get("last_contact_speed")) > 0.16,
            "Contact response not driven by observed physical velocity")
        _check(bool(skin.get("active")), "Real contact should start local felt response")
        await create_timer(0.45).timeout
        _check(not bool(skin.get("active")),"Felt must recover promptly, never wobble forever")
    print("M5_REAL_FELT_CONTACT checks=%d failures=%d" % [checks,failures])
    scene.queue_free()
    quit(0 if failures == 0 else 1)
