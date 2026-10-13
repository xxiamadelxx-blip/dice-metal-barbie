extends SceneTree
## One authentic physics throw per die with a READY -> GO -> DONE handshake.
## Continuous screen recording is done externally by FFmpeg, not fake motion.
const ShapeMath = preload("res://src/core/trapezohedron.gd")
const Rules = preload("res://src/core/dice_rules.gd")
const TYPES: Array[String] = ["4", "6", "8", "12", "20", "10", "100", "100_PAIR"]
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
    for dice_key in TYPES:
        var sides: int = 100 if dice_key == "100_PAIR" else int(dice_key)
        scene.call("_select_die_type", sides)
        if sides == 100:
            var wants_pair := dice_key == "100_PAIR"
            if bool(scene.get("percentile_pair_enabled")) != wants_pair:
                scene.call("_toggle_d100_mode")
        if not _write("ready-D%s" % dice_key, "real window initialized\n"):
            quit(23)
            return
        if not await _wait_for("go-D%s" % dice_key, 75.0):
            quit(24)
            return
        var start_us := Time.get_ticks_usec()
        var frame_start := Engine.get_frames_drawn()
        scene.call("_throw_selected_die")
        var bodies: Array[RigidBody3D] = []
        if dice_key == "100_PAIR":
            var pair := scene.get_node_or_null("PhysicalD100Percentile") as Node3D
            if pair != null:
                for child_name in ["TensD10", "OnesD10"]:
                    var child := pair.get_node_or_null(child_name) as RigidBody3D
                    if child != null:
                        bodies.append(child)
            if bodies.size() != 2:
                push_error("D100_PAIR requires two real Jolt D10 rigid bodies")
                quit(25)
                return
        else:
            var physical := scene.get_node_or_null("PhysicalD%d" % sides) as RigidBody3D
            if physical == null:
                push_error("D%s Jolt body is missing" % dice_key)
                quit(25)
                return
            bodies.append(physical)
        var result := -1
        var limit := Time.get_ticks_msec() + (27000 if sides == 100 else 12000)
        while Time.get_ticks_msec() < limit:
            await process_frame
            result = int(scene.get("last_result"))
            if result >= 1 and result <= sides:
                break
            for physical in bodies:
                if not is_instance_valid(physical):
                    push_error("D%s physical body disappeared" % dice_key)
                    quit(26)
                    return
                if not bool(physical.get("rolling")) and int(physical.get("result")) < 1:
                    push_error("D%s real Jolt roll failed: %s" %
                        [dice_key, str(physical.get("failure"))])
                    quit(27)
                    return
        if result < 1 or result > sides:
            push_error("D%s physical throw never resolved" % dice_key)
            quit(28)
            return
        # A successful HUD readout is not enough. For new D10/D100 verify
        # that every physical source body's genuinely uppermost face agrees.
        if dice_key == "100_PAIR":
            var tens: int = ShapeMath.top_value(10,
                bodies[0].global_transform.basis.orthonormalized())
            var ones: int = ShapeMath.top_value(10,
                bodies[1].global_transform.basis.orthonormalized())
            var expected: int = Rules.percentile((tens % 10) * 10, ones % 10)
            if tens < 1 or ones < 1 or expected != result or (
                int(bodies[0].get("result")) != tens or
                int(bodies[1].get("result")) != ones):
                push_error("D100 pair settled face/HUD disagreement")
                quit(32)
                return
        elif sides == 10 or sides == 100:
            var top: int = ShapeMath.top_value(sides,
                bodies[0].global_transform.basis.orthonormalized())
            if top != result or int(bodies[0].get("result")) != result:
                push_error("D%s settled face/HUD disagreement" % dice_key)
                quit(33)
                return
        var outcome_us := Time.get_ticks_usec()
        var frame_count := Engine.get_frames_drawn() - frame_start
        await create_timer(1.0).timeout
        var duration_us := Time.get_ticks_usec() - start_us
        if not _write("timeline-D%s.json" % dice_key, JSON.stringify({
            "die": sides,
            "capture_key": dice_key,
            "percentile_pair": dice_key == "100_PAIR",
            "physics_bodies": bodies.size(),
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
        if not _write("done-D%s" % dice_key, "D%s physical result=%d\n" % [dice_key, result]):
            quit(30)
            return
        # Keep the actual Godot window alive until the recorder confirms it
        # flushed this video. Without this handshake the last D20 clip ended
        # with five false black-screen frames after Godot quit.
        if not await _wait_for("saved-D%s" % dice_key, 30.0):
            quit(31)
            return
        print("TEMPORAL_ROLL D%s=%d drawn_frames=%d" % [dice_key,result,frame_count])
    print("PASS all eight real physical throws finished with timeline markers")
    quit(0)
