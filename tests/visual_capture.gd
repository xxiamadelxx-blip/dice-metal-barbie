extends SceneTree
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
    scene.call("_throw_physical_d20")
    await create_timer(0.7).timeout
    await _capture("native-04-d20-moving")
    await create_timer(5.0).timeout
    await _capture("native-05-d20-after")
    print("Native Godot visual capture completed; inspect actual dice and HUD.")
    quit(0)
