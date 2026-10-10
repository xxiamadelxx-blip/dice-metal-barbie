extends SceneTree
## One authentic physics throw per die with a READY -> GO -> DONE handshake.
## Continuous screen recording is done externally by FFmpeg, not fake motion.
const TYPES: Array[int] = [4, 6, 8, 12, 20]
const OUT := "res://qa-evidence/temporal"

func _initialize() -> void:
    call_deferred("_run")

func _write(name: String, payload: String) -> bool:
    var handle := FileAccess.open(OUT + "/" + name, FileAccess.WRITE)
    if handle == null:
        push_error("Timeline marker could not be written: " + name)
        return false
    handle.store_string(payload)
    handle.close()
    return true

func _wait_for(name: String, seconds: float) -> bool:
    var limit := Time.get_ticks_msec() + int(seconds * 1000.0)
    while not FileAccess.file_exists(OUT + "/" + name):
        if Time.get_ticks_msec() >= limit:
            push_error("Capture controller did not signal " + name)
            return false
        await process_frame
    return true

func _run() -> void:
    root.size = Vector2i(720, 1280)
    if DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT)) != OK:
        push_error("Timeline directory could not be created")
        quit(20)
        return
    var packed: PackedScene = load("res://src/main.tscn")
    if packed == null:
        push_error("Missing main Godot scene")
        quit(21)
        return
    var scene := packed.instantiate() as Node3D
    if scene == null:
        push_error("Expected playable 3D scene")
        quit(22)
        return
    root.add_child(scene)
    await create_timer(1.0).timeout
    for sides in TYPES:
        scene.call("_select_die_type", sides)
        if not _write("ready-D%d" % sides, "real window initialized\n"):
            quit(23)
            return
        if not await _wait_for("go-D%d" % sides, 75.0):
            quit(24)
            return
        var start_us := Time.get_ticks_usec()
        var frame_start := Engine.get_frames_drawn()
        scene.call("_throw_selected_die")
        var physical := scene.get_node_or_null("PhysicalD%d" % sides) as RigidBody3D
        if physical == null:
            push_error("D%d Jolt die is missing" % sides)
            quit(25)
            return
        var result := -1
        var limit := Time.get_ticks_msec() + 12000
        while Time.get_ticks_msec() < limit:
            await process_frame
            result = int(scene.get("last_result"))
            if result >= 1 and result <= sides:
                break
            if not is_instance_valid(physical):
                push_error("D%d physical body disappeared" % sides)
                quit(26)
                return
            if not bool(physical.get("rolling")) and result == -1:
                push_error("D%d physical roll failed" % sides)
                quit(27)
                return
        if result < 1 or result > sides:
            push_error("D%d physical throw never resolved" % sides)
            quit(28)
            return
        var outcome_us := Time.get_ticks_usec()
        var frame_count := Engine.get_frames_drawn() - frame_start
        await create_timer(1.0).timeout
        var duration_us := Time.get_ticks_usec() - start_us
        if not _write("timeline-D%d.json" % sides, JSON.stringify({
            "die": sides,
            "result": result,
            "source": "real Godot Jolt physical body",
            "environment": "LINUX_MESA_NATIVE_NOT_ANDROID_EMULATOR",
            "physics_tick_hz": 120,
            "nominal_screen_recording_hz": 24,
            "seconds_to_result": float(outcome_us - start_us) / 1000000.0,
            "seconds_from_go_to_done": float(duration_us) / 1000000.0,
            "godot_drawn_frames_to_result": frame_count,
            "status": "completed"
        })):
            quit(29)
            return
        if not _write("done-D%d" % sides, "D%d physical result=%d\n" % [sides, result]):
            quit(30)
            return
        # Keep the actual Godot window alive until the recorder confirms it
        # flushed this video. Without this handshake the last D20 clip ended
        # with five false black-screen frames after Godot quit.
        if not await _wait_for("saved-D%d" % sides, 30.0):
            quit(31)
            return
        print("TEMPORAL_ROLL D%d=%d drawn_frames=%d" % [sides,result,frame_count])
    print("PASS all five real physical throws finished with timeline markers")
    quit(0)
