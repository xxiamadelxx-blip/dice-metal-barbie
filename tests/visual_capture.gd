extends SceneTree
const CriticalAura = preload("res://src/visual/critical_aura.gd")
## Cloud native visual fallback for inspecting the actual Godot render output.
## Runs under Xvfb/Mesa, not an Android APK. NEVER claim handset equivalence.

func _initialize() -> void:
    call_deferred("_run")

func _capture(name: String) -> void:
    await RenderingServer.frame_post_draw
    var rendered: Image = root.get_texture().get_image()
    if rendered == null or rendered.is_empty():
        push_error("No rendered frame: %s" % name)
        quit(3)
        return
    var dest := "res://qa-evidence/" + name + ".png"
    var err := rendered.save_png(dest)
    if err != OK:
        push_error("Cannot save native capture: %s error %d" % [dest, err])
        quit(4)
        return
    print("Captured actual Godot native renderer frame: %s size=%s" % [dest, rendered.get_size()])

func _run() -> void:
    root.size = Vector2i(720, 1280)
    var packed: PackedScene = load("res://src/main.tscn")
    if packed == null:
        push_error("Main scene unavailable")
        quit(2)
        return
    var scene: Node3D = packed.instantiate()
    root.add_child(scene)
    await create_timer(1.5).timeout
    await _capture("native-01-launch")
    scene.call("_throw_physical_d6")
    await create_timer(0.7).timeout
    await _capture("native-02-moving")
    await create_timer(5.0).timeout
    await _capture("native-03-after")
    # The user-approved concept emphasizes sculptural polyhedra. The old
    # screenshot suite showed D6 only, which looks square from 90° overhead.
    # Also inspect the real faceted D20, not a staged illustration.
    scene.call("_select_die_type", 20)
    scene.call("_throw_physical_d20")
    await create_timer(0.7).timeout
    await _capture("native-04-d20-moving")
    await create_timer(5.0).timeout
    await _capture("native-05-d20-after")
    # This genuine overhead detail view is essential for evaluating whether
    # 3D text and pocket geometry hold up beyond the tiny full-table preview.
    var closeup_camera := scene.get_node_or_null("FixedOverheadCamera") as Camera3D
    var closeup_die := scene.get_node_or_null("PhysicalD20") as RigidBody3D
    if closeup_camera == null or closeup_die == null:
        push_error("Cannot make a truthful native D20 detail capture")
        quit(6)
        return
    closeup_camera.size = 3.8
    closeup_camera.position = Vector3(closeup_die.position.x, 18.0, closeup_die.position.z)
    await create_timer(0.5).timeout
    await _capture("native-06-d20-detail")
    # Controlled *visual-only* effect staging on a genuine settled die.
    # NOT evidence that the random physical result was a natural crit.
    # Physics result triggering is separately guarded in main.gd and unit tests.
    var gold_aura := CriticalAura.spawn(closeup_die, 20, 20)
    if gold_aura == null:
        push_error("Unable to stage golden spatial D20 aura in native renderer")
        quit(7)
        return
    await create_timer(0.18).timeout
    await _capture("native-07-staged-gold-pulse")
    await create_timer(1.1).timeout
    var red_aura := CriticalAura.spawn(closeup_die, 20, 1)
    if red_aura == null:
        push_error("Unable to stage crimson spatial D20 aura in native renderer")
        quit(8)
        return
    await create_timer(0.18).timeout
    await _capture("native-08-staged-crimson-pulse")
    print("Native Godot visual capture complete; pulses are STAGED EFFECT PREVIEWS, not natural dice outcomes.")
    quit(0)
