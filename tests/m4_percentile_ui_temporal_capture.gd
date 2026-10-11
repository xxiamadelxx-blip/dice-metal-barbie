extends SceneTree
## True 720x1280 Godot/Mesa recorder, 24 captured frames per second.
## Both independently numbered real physical percentile D10 bodies visibly
## roll TWICE; every actual old/new upper face becomes a local history entry.
const OUT := "res://qa-evidence/m4-percentile-24fps"
func _initialize() -> void:
    call_deferred("_run")
func _write(key: String, content: String) -> bool:
    var f := FileAccess.open(OUT+"/"+key,FileAccess.WRITE)
    if f == null:
        push_error("Cannot save actual percentile capture marker "+key)
        return false
    f.store_string(content)
    f.close()
    return true
func _wait(key: String, seconds: float) -> bool:
    var limit := Time.get_ticks_msec()+int(seconds*1000)
    while not FileAccess.file_exists(OUT+"/"+key):
        if Time.get_ticks_msec()>limit:
            return false
        await process_frame
    return true
func _settle(pool: Node3D, seconds: float) -> bool:
    var limit := Time.get_ticks_msec()+int(seconds*1000)
    while bool(pool.get("busy")):
        if Time.get_ticks_msec()>limit:
            return false
        await physics_frame
    return true
func _run() -> void:
    root.size=Vector2i(720,1280)
    DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
    var scene := load("res://src/main.tscn").instantiate() as Node3D
    root.add_child(scene)
    await create_timer(1).timeout
    var panel := scene.get("advanced_panel") as PanelContainer
    var menu := scene.get_node_or_null("GameHUD/OverlayRoot/OpenAdvancedRules") as Button
    if panel==null or menu==null:
        push_error("No actual production mobile M4 drawer for pair capture")
        quit(20)
        return
    if not _write("ready","M4 physical percentile video window ready"):
        quit(21)
        return
    if not await _wait("go",60):
        quit(22)
        return
    await create_timer(1).timeout
    menu.pressed.emit()
    var formula := panel.get("formula_input") as LineEdit
    var mode := panel.get("hundred_modes") as OptionButton
    var thrower := panel.get("roll_button") as Button
    formula.text="1d100+1d4-2"
    mode.select(0)
    await create_timer(1).timeout
    thrower.pressed.emit()
    var pool := scene.get("physical_pool") as Node3D
    if pool==null or not bool(pool.get("busy")):
        push_error("Real paired percentile D100 HUD did not launch both D10")
        quit(23)
        return
    var frames_start := Engine.get_frames_drawn()
    var t0 := Time.get_ticks_usec()
    if not await _settle(pool,55):
        push_error("Real paired D100 and D4 did not physically settle")
        quit(24)
        return
    var first: Dictionary = pool.get("last_result")
    var bodies: Array = pool.get("_active")
    if not bool(first.get("ok",false)) or bodies.size()!=3:
        push_error("Original percentile Jolt had invalid physical source count")
        quit(25)
        return
    var old_pair: Array = first["groups"][0]["percentile_source_d10_faces"][0]
    if old_pair != [bodies[0].get("result"),bodies[1].get("result")]:
        push_error("Original actual D10 source faces do not match Godot/Jolt")
        quit(26)
        return
    var kept: int = int(bodies[2].get("result"))
    var first_total := int(first["total"])
    await create_timer(0.75).timeout
    menu.pressed.emit()
    var pick := panel.find_child("ChoosePhysicalDieToReroll",true,false) as OptionButton
    var reroll := panel.find_child("RerollChosenPhysicalDie",true,false) as Button
    if not panel.visible or pick==null or reroll==null or reroll.disabled or (
            not pick.get_item_text(0).contains("2×D10")):
        push_error("Physical 2×D10 player selector unavailable on mobile capture")
        quit(27)
        return
    await create_timer(0.75).timeout
    reroll.pressed.emit()
    if not bool(pool.get("busy")) or panel.visible:
        push_error("Real Android-size UI reroll never launched both source dice")
        quit(28)
        return
    if not await _settle(pool,55):
        push_error("Both native Jolt percentile D10 rerolls did not stop")
        quit(29)
        return
    var final: Dictionary = pool.get("last_result")
    if not bool(final.get("ok",false)) or (pool.get("_active") as Array).size()!=3:
        push_error("Percentile pair physical result lost bodies")
        quit(30)
        return
    var history: Array = final["groups"][0]["percentile_source_d10_faces"][0]
    if history.size()!=2 or history[0]!=old_pair or (
            history[1] != [bodies[0].get("result"),bodies[1].get("result")]):
        push_error("Player-selected D100 did not preserve real old/new source digits")
        quit(31)
        return
    if int(bodies[2].get("result"))!=kept or not bodies[2].freeze:
        push_error("The unrelated D4 was changed during real paired D100 reroll")
        quit(32)
        return
    await create_timer(0.85).timeout
    menu.pressed.emit()
    var open_history := panel.find_child("OpenFullPhysicalHistory",true,false) as Button
    if open_history==null:
        push_error("No real player offline history button")
        quit(33)
        return
    open_history.pressed.emit()
    await process_frame
    var dialog := scene.get("history_dialog") as AcceptDialog
    if dialog==null or not dialog.visible:
        push_error("Full player history not present in real film")
        quit(34)
        return
    var shown := dialog.find_child("ActualIndividualFacesAndRerolls",true,false) as RichTextLabel
    if shown==null or not shown.text.contains("физические пары D10"):
        push_error("Full history did not show both actual percentile source pairs")
        quit(35)
        return
    await create_timer(1.1).timeout
    dialog.hide()
    panel.visible=false
    await create_timer(0.45).timeout
    var state: Dictionary = scene.get("roll_store").call("snapshot")
    if (state.get("history",[]) as Array).size()<2:
        push_error("Actual percentile rethrow did not persist offline before capture")
        quit(36)
        return
    var summary := {"status":"completed",
        "provenance":"REAL_GODOT_JOLT_ON_MESA_XVFB_NOT_ANDROID",
        "physical_formula":"1d100+1d4-2",
        "real_physical_sources":bodies.size(),
        "original_D100":first["groups"][0]["kept_faces"][0],
        "rerolled_D100":final["groups"][0]["kept_faces"][0],
        "original_and_new_real_D10_pairs":history,
        "untouched_D4":kept,
        "final_sum":final["total"],
        "two_Jolt_sources_physically_rerolled":true,
        "original_and_repeated_outcomes_stored":true,
        "physical_seconds":float(Time.get_ticks_usec()-t0)/1000000.0,
        "drawn_frames":Engine.get_frames_drawn()-frames_start}
    if not _write("summary.json",JSON.stringify(summary,"  ")+"\n"):
        quit(37)
        return
    _write("done","all source physical D10 results settled and history visible\n")
    if not await _wait("saved",30):
        quit(38)
        return
    print("PASS M4 UI actual real Jolt paired percentile D100: "+JSON.stringify(summary))
    quit(0)
