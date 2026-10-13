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
    await create_timer(0.5).timeout
    var formula := panel.get("formula_input") as LineEdit
    var send := panel.get("roll_button") as Button
    # This segment of the SAME original 24fps recording includes the new
    # hidden-by-default physically correct pool composer, not a screenshot mock.
    formula.text = "1d6+1d4-3"
    var edit_pool := panel.find_child("OpenPhysicalPoolComposer",true,false) as Button
    var editor := panel.get("pool_composer") as ConfirmationDialog
    if edit_pool==null or editor==null:
        push_error("Actual pool composer missing from native visual capture")
        quit(60)
        return
    edit_pool.pressed.emit()
    await process_frame
    if not editor.visible:
        push_error("User pool composition modal not actually opened")
        quit(61)
        return
    await create_timer(1.0).timeout
    var increment := editor.find_child("IncreaseGroupCount",true,false) as Button
    var decrement := editor.find_child("DecreaseGroupCount",true,false) as Button
    if increment==null or decrement==null:
        push_error("Real group count stepper missing from pool composer")
        quit(62)
        return
    # Video evidence must contain the actual usable controls INSIDE the
    # popup; an all-height scrolling list once hid them beyond the screen.
    for name in ["IncreaseGroupCount","AddPhysicalGroup",
            "RemovePhysicalGroup","IncreasePoolModifier","POOL_OK_BUTTON"]:
        var visible_button: Button = editor.get_ok_button() if (
            name=="POOL_OK_BUTTON") else (
            editor.find_child(name,true,false) as Button)
        if visible_button==null or not visible_button.is_visible_in_tree():
            push_error("Visible screenshot lacks actual pool button "+name)
            quit(64)
            return
        var bounds := visible_button.get_global_rect()
        if bounds.position.y<0 or bounds.end.y>=float(editor.size.y)-2.0:
            push_error("Real Android-sized M4 composer rendered button offscreen: "+
                name+" "+str(bounds)+" modal "+str(editor.size))
            quit(65)
            return
    increment.pressed.emit()
    await create_timer(0.6).timeout
    decrement.pressed.emit()
    await create_timer(0.4).timeout
    editor.get_ok_button().pressed.emit()
    if formula.text != "1d6+1d4-3":
        push_error("Composition round-trip changed accepted Jolt fixture")
        quit(63)
        return
    await create_timer(0.3).timeout
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
    # The 24fps evidence must demonstrate two real settled Jolt meshes,
    # not a single surviving die with fabricated arithmetic.
    var physically_visible: Array = pool.get("_active")
    if physically_visible.size() != 2 or int(pool.get("peak_simultaneously_rolling")) < 2:
        push_error("M4 live window did NOT roll/retain two physical bodies together")
        quit(41)
        return
    for source_body in physically_visible:
        var rigid := source_body as RigidBody3D
        if rigid == null or rigid.get_parent() != pool or not rigid.sleeping:
            push_error("M4 live window lost a genuine settled Jolt body")
            quit(42)
            return
    var elapsed := float(Time.get_ticks_usec()-physical_start)/1000000.0
    var frames_drawn := Engine.get_frames_drawn()-count_start
    var first_total := int(result["total"])
    var first_face: int = int(result["groups"][0]["attempts"][0][0])
    await create_timer(0.6).timeout

    # Continue the SAME uncropped 24fps original source recording through
    # real on-screen selection and Jolt reroll of ONLY the first D6.
    button.pressed.emit()
    var choose := panel.find_child("ChoosePhysicalDieToReroll",true,false) as OptionButton
    var reroll := panel.find_child("RerollChosenPhysicalDie",true,false) as Button
    if not panel.visible or choose == null or reroll == null or reroll.disabled:
        push_error("M4 actual drawer has no usable selectable real-die reroll")
        quit(43)
        return
    await create_timer(0.75).timeout
    var reroll_started := Time.get_ticks_usec()
    var reroll_frames := Engine.get_frames_drawn()
    reroll.pressed.emit()
    if not bool(pool.get("busy")) or panel.visible:
        push_error("Real M4 reroll click did not start genuine dynamic Jolt")
        quit(44)
        return
    max_until = Time.get_ticks_msec()+55000
    while bool(pool.get("busy")):
        if Time.get_ticks_msec() > max_until:
            push_error("Actual selected physical source reroll timed out")
            quit(45)
            return
        await physics_frame
    result = pool.get("last_result")
    var new_attempts: Array = result["groups"][0]["attempts"][0] if bool(result.get("ok",false)) else []
    if new_attempts.size()!=2 or int(new_attempts[0])!=first_face or (
            int(new_attempts[-1])!=int((pool.get("_active") as Array)[0].get("result"))):
        push_error("Actual 24fps reroll did not preserve original and new physical faces")
        quit(46)
        return
    elapsed += float(Time.get_ticks_usec()-reroll_started)/1000000.0
    frames_drawn += Engine.get_frames_drawn()-reroll_frames
    await create_timer(1.3).timeout
    var store: RefCounted = scene.get("roll_store")
    var history: Array = store.call("snapshot")["history"]
    if history.is_empty() or int(history[0]["total"]) != int(result["total"]):
        push_error("M4 actual on-screen result not saved in offline history")
        quit(37)
        return
    # An additional capture section must show the REAL detailed local
    # history dialog, including both genuine source faces after the reroll.
    button.pressed.emit()
    var open_history := panel.find_child("OpenFullPhysicalHistory",true,false) as Button
    if open_history == null:
        push_error("M4 history visual capture has no full history button")
        quit(47)
        return
    open_history.pressed.emit()
    await process_frame
    var history_dialog := scene.get("history_dialog") as AcceptDialog
    if history_dialog == null or not history_dialog.visible:
        push_error("M4 history popup never appeared in the real screenshot")
        quit(48)
        return
    if int(history_dialog.call("visible_record_count")) < 2:
        push_error("M4 history popup omitted original or rerolled physical cast")
        quit(49)
        return
    await create_timer(1.6).timeout
    history_dialog.hide()
    panel.visible = false
    await create_timer(0.3).timeout
    # The SAME original FFmpeg footage now continues through real physical
    # D100 percentile source selection, tens reroll and ones reroll.
    button.pressed.emit()
    formula.text = "1d100+1d6"
    send.pressed.emit()
    pool = scene.get("physical_pool") as Node3D
    if pool == null or not bool(pool.get("busy")):
        push_error("Real D100 pair formula UI failed to launch Jolt")
        quit(50)
        return
    var pair_start := Time.get_ticks_usec()
    var pair_frames := Engine.get_frames_drawn()
    max_until = Time.get_ticks_msec()+55000
    while bool(pool.get("busy")):
        if Time.get_ticks_msec()>max_until:
            push_error("Original paired percentile Jolt visual cast timed out")
            quit(51)
            return
        await physics_frame
    var pair_result: Dictionary = pool.get("last_result")
    var pair_bodies: Array = pool.get("_active")
    if not bool(pair_result.get("ok",false)) or pair_bodies.size()!=3:
        push_error("Visual D100 pair was not two D10 plus one D6")
        quit(52)
        return
    var original_pair: Array = pair_result["groups"][0]["percentile_source_d10_faces"][0]
    var other_face := int((pair_bodies[2] as RigidBody3D).get("result"))
    for digit in ["tens","ones"]:
        await create_timer(0.35).timeout
        button.pressed.emit()
        if not panel.visible:
            push_error("Physical D100 source picker did not visibly reopen")
            quit(53)
            return
        choose.select(0 if digit=="tens" else 1)
        var slots: Array = panel.get("reroll_slots")
        if slots.size()<2 or slots[choose.selected].get("digit","")!=digit:
            push_error("Source picker selected wrong actual percentile D10")
            quit(54)
            return
        await create_timer(0.55).timeout
        reroll.pressed.emit()
        if not bool(pool.get("busy")) or panel.visible:
            push_error("Source picker did not launch new visible Jolt throw")
            quit(55)
            return
        max_until = Time.get_ticks_msec()+55000
        while bool(pool.get("busy")):
            if Time.get_ticks_msec()>max_until:
                push_error("Selected true percentile D10 capture timed out")
                quit(56)
                return
            await physics_frame
        pair_result = pool.get("last_result")
        if not bool(pair_result.get("ok",false)):
            push_error("Actual selected percentile Jolt result invalid")
            quit(57)
            return
        var states: Array = pair_result["groups"][0]["percentile_source_d10_attempts"][0]
        var actual_tens := int((pair_bodies[0] as RigidBody3D).get("result"))
        var actual_ones := int((pair_bodies[1] as RigidBody3D).get("result"))
        if states.size()!=(2 if digit=="tens" else 3) or (
                int(states[0][0])!=int(original_pair[0])) or (
                int(states[0][1])!=int(original_pair[1])) or (
                int(states[-1][0])!=actual_tens) or (
                int(states[-1][1])!=actual_ones) or (
                int((pair_bodies[2] as RigidBody3D).get("result"))!=other_face):
            push_error("Visual D100 source chronology diverges from visible Jolt")
            quit(58)
            return
    elapsed += float(Time.get_ticks_usec()-pair_start)/1000000.0
    frames_drawn += Engine.get_frames_drawn()-pair_frames
    await create_timer(0.35).timeout
    button.pressed.emit()
    open_history.pressed.emit()
    await process_frame
    var actual_source_detail := history_dialog.find_child(
        "ActualIndividualFacesAndRerolls",true,false) as RichTextLabel
    if not history_dialog.visible or actual_source_detail == null or (
            not actual_source_detail.text.contains("десятки/единицы")):
        push_error("Full physical history omitted photographed paired-D10 attempts")
        quit(59)
        return
    await create_timer(1.0).timeout
    history_dialog.hide()
    panel.visible = false
    await create_timer(0.2).timeout
    var real_pair_states: Array = pair_result["groups"][0]["percentile_source_d10_attempts"][0]
    var summary := {"provenance":"REAL_LINUX_MESA_GODOT_JOLT_HUD_NOT_ANDROID",
        "physical_formula":result["formula"],"real_Jolt_result":result["total"],
        "real_physical_groups":result["groups"].size(),
        "original_real_total_before_reroll":first_total,
        "rerolled_actual_source_trace":new_attempts,
        "native_real_player_reroll":true,
        "paired_D100_genuine_tens_and_ones_rerolls":true,
        "paired_D100_source_digit_states":real_pair_states,
        "paired_D100_actual_total":pair_result["total"],
        "paired_D100_original_Jolt_bodies_retained":pair_bodies.size(),
        "paired_D100_history_dialog_showed_digit_chronology":true,
        "real_history_popup_showed_both_physical_results":true,
        "real_visible_retained_Jolt_bodies":physically_visible.size(),
        "peak_simultaneously_rolling":int(pool.get("peak_simultaneously_rolling")),
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
