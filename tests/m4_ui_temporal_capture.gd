extends SceneTree
## Live Godot/Jolt mobile HUD: READY/GO/DONE/SAVED temporal handshake.
## FFmpeg captures genuinely rendered Linux Mesa pixels at nominal 24fps.
const OUT := "res://qa-evidence/m4-ui-24fps"

func _initialize() -> void:
    call_deferred("_run")

func _write(name: String, text: String) -> bool:
    var file := FileAccess.open(OUT+"/"+name,FileAccess.WRITE)
    if file == null:
        push_error("M4 capture missing writable marker: "+name)
        return false
    file.store_string(text)
    file.close()
    return true

func _wait(name: String, seconds: float) -> bool:
    var until := Time.get_ticks_msec()+int(seconds*1000.0)
    while not FileAccess.file_exists(OUT+"/"+name):
        if Time.get_ticks_msec()>until:
            push_error("M4 screen capture waited too long: "+name)
            return false
        await process_frame
    return true

func _run() -> void:
    root.size = Vector2i(720,1280)
    DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
    var scene := load("res://src/main.tscn").instantiate() as Node3D
    root.add_child(scene)
    await create_timer(1.1).timeout
    var panel := scene.get("advanced_panel") as PanelContainer
    var button := scene.get_node_or_null("GameHUD/OverlayRoot/OpenAdvancedRules") as Button
    if panel == null or button == null:
        push_error("Actual visual advanced M4 controls not found")
        quit(30)
        return
    if not _write("ready","Real Godot mobile UX window visibly initialized"):
        quit(31)
        return
    if not await _wait("go",60.0):
        quit(32)
        return
    await create_timer(1.0).timeout
    button.pressed.emit()
    if not panel.visible:
        push_error("Actual advanced drawer click failed")
        quit(33)
        return
    await create_timer(1.25).timeout
    var formula := panel.get("formula_input") as LineEdit
    var send := panel.get("roll_button") as Button
    formula.text = "1d6+1d4-3"
    send.pressed.emit()
    var pool := scene.get("physical_pool") as Node3D
    if pool == null or not bool(pool.get("busy")):
        push_error("Visible M4 button did not start real Jolt")
        quit(34)
        return
    var physical_start := Time.get_ticks_usec()
    var count_start := Engine.get_frames_drawn()
    var max_until := Time.get_ticks_msec()+55000
    while bool(pool.get("busy")):
        if Time.get_ticks_msec()>max_until:
            push_error("Real mixed Jolt throw failed to stop")
            quit(35)
            return
        await physics_frame
    var result: Dictionary = pool.get("last_result")
    if not bool(result.get("ok",false)) or int(scene.get("last_result")) != int(result.get("total",-999)):
        push_error("M4 visible total not derived from actual Jolt face")
        quit(36)
        return
    var elapsed := float(Time.get_ticks_usec()-physical_start)/1000000.0
    var frames_drawn := Engine.get_frames_drawn()-count_start
    await create_timer(1.3).timeout
    var store: RefCounted = scene.get("roll_store")
    var history: Array = store.call("snapshot")["history"]
    if history.is_empty() or int(history[0]["total"]) != int(result["total"]):
        push_error("M4 actual on-screen result not saved in offline history")
        quit(37)
        return
    var summary := {"provenance":"REAL_LINUX_MESA_GODOT_JOLT_HUD_NOT_ANDROID",
        "physical_formula":result["formula"],"real_Jolt_result":result["total"],
        "real_physical_groups":result["groups"].size(),
        "seconds_real_body_rolls":elapsed,
        "frames_drawn_during_real_physics":frames_drawn,
        "status":"completed"}
    if not _write("summary.json",JSON.stringify(summary,"  ")+"\n"):
        quit(38)
        return
    if not _write("done","actual physics completed and real visible UI updated\n"):
        quit(39)
        return
    if not await _wait("saved",30):
        quit(40)
        return
    print("PASS M4 UI actual real Jolt physical formula and saved history: "+JSON.stringify(summary))
    quit(0)
