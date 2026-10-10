extends SceneTree
## M2 actual scene startup and rigid-body motion integration smoke.
## Run: godot --headless --path . --script res://tests/physics_smoke.gd

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    var packed: PackedScene = load("res://src/main.tscn")
    if packed == null:
        push_error("Cannot load startup scene")
        quit(1)
        return

    var instance: Node3D = packed.instantiate()
    root.add_child(instance)
    await process_frame

    var camera: Camera3D = instance.get_node_or_null("FixedOverheadCamera")
    if camera == null or camera.projection != Camera3D.PROJECTION_ORTHOGONAL:
        push_error("Fixed overhead camera missing")
        quit(1)
        return
    if camera.rotation_degrees.distance_to(Vector3(-90, 0, 0)) > 0.01:
        push_error("Camera is tilted, expected exact vertical top-down")
        quit(1)
        return

    instance.call("_throw_physical_d6")
    await physics_frame
    var die: RigidBody3D = instance.get_node_or_null("PhysicalD6")
    if die == null:
        push_error("D6 button did not spawn a rigid body")
        quit(1)
        return

    var original: Vector3 = die.position
    for frame in range(240):
        await physics_frame
    if not is_instance_valid(die):
        push_error("D6 vanished during physics test")
        quit(1)
        return
    var final_position: Vector3 = die.position
    if original.distance_to(final_position) < 0.1:
        push_error("Rigid body did not move under impulse/gravity")
        quit(1)
        return
    if absf(final_position.x) > 3.65 or absf(final_position.z) > 5.65 or final_position.y < -0.2:
        push_error("D6 escaped table bounds: %s" % [final_position])
        quit(1)
        return

    print("M2 physics integration smoke: PASS, camera vertical, rigid body moved inside rails")
    quit(0)
