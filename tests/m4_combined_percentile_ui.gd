extends SceneTree
## LIVE Godot GUI signals, same game scene and Jolt source bodies as production.
## Percentile D100 is a TWO physical D10 pool, never fake scripted values.
var checks := 0
var failures := 0
func _initialize() -> void:
    call_deferred("_run")
func _check(value: bool, message: String) -> void:
    checks += 1
    if not value:
        failures += 1
        push_error(message)
func _wait(pool: Node3D) -> bool:
    for tick in range(12000):
        await physics_frame
        if not bool(pool.get("busy")):
            return true
    return false
func _run() -> void:
    root.size = Vector2i(720,1280)
    var scene := load("res://src/main.tscn").instantiate() as Node3D
    root.add_child(scene)
    await process_frame
    var open := scene.get_node_or_null("GameHUD/OverlayRoot/OpenAdvancedRules") as Button
    var drawer := scene.get("advanced_panel") as PanelContainer
    _check(open!=null and drawer!=null,"Advanced panel missing from production game scene")
    if failures>0:
        quit(1)
        return
    open.pressed.emit()
    var input := drawer.get("formula_input") as LineEdit
    var choose_d100 := drawer.get("hundred_modes") as OptionButton
    var play := drawer.get("roll_button") as Button
    input.text="1d100+1d4-2"
    choose_d100.select(0)
    play.pressed.emit()
    var pool := scene.get("physical_pool") as Node3D
    _check(pool!=null and bool(pool.get("busy")),
        "Actual GUI did not start genuine percentile D100/Jolt body pool")
    if pool==null:
        quit(1)
        return
    _check(await _wait(pool),"Actual original 2-D10 plus D4 throw timed out")
    var first: Dictionary = pool.get("last_result")
    _check(bool(first.get("ok",false)),"Initial selected D100 body faces missing")
    if failures>0:
        quit(1)
        return
    var bodies: Array = pool.get("_active")
    _check(bodies.size()==3,"1d100+1d4 must have three real source bodies")
    var old_tens: int = int(bodies[0].get("result"))
    var old_ones: int = int(bodies[1].get("result"))
    var kept_d4: int = int(bodies[2].get("result"))
    open.pressed.emit()
    _check(drawer.visible,"Player cannot reopen the advanced formula drawer")
    var chooser := drawer.find_child("ChoosePhysicalDieToReroll",true,false) as OptionButton
    var reroll := drawer.find_child("RerollChosenPhysicalDie",true,false) as Button
    _check(chooser!=null and reroll!=null and not reroll.disabled,
        "Paired D100 must appear as a supported logical reroll choice")
    if chooser==null or reroll==null:
        quit(1)
        return
    _check(chooser.get_item_text(0).contains("ОБА"),
        "Player is not told that one D100 rerolls BOTH physical D10 bodies")
    reroll.pressed.emit()
    _check(bool(pool.get("busy")) and not drawer.visible,
        "Real paired D100 player click did not trigger active physics")
    _check(await _wait(pool),"Both actual D10 did not settle after user click")
    var result: Dictionary = pool.get("last_result")
    _check(bool(result.get("ok",false)),"Paired Jolt player reroll did not resolve")
    if result.get("ok",false):
        var unchanged: Array = pool.get("_active")
        _check(unchanged.size()==3 and unchanged[0]==bodies[0] and
            unchanged[1]==bodies[1] and unchanged[2]==bodies[2],
            "GUI reroll removed or replaced original physical sources")
        _check(int(bodies[2].get("result"))==kept_d4 and bodies[2].freeze,
            "Unselected real D4 was rethrown instead of logical D100")
        var pair_history: Array = result["groups"][0]["percentile_source_d10_attempts"][0]
        _check(result["groups"][0]["percentile_reroll_modes"][0]==["both"],
            "Full-pair physical action must not replace existing tens/ones modes")
        _check(pair_history.size()==2 and pair_history[0]==[old_tens,old_ones],
            "Original physical D100 source pair disappeared from UI result")
        _check(pair_history[1]==[bodies[0].get("result"),bodies[1].get("result")],
            "Updated percentile D10 faces do not match actual Jolt bodies")
        var saved_history: Array = scene.get("roll_store").call("snapshot")["history"]
        _check(not saved_history.is_empty() and
            saved_history[0]["groups"][0]["attempts"][0].size()==2,
            "Player's actual physical paired reroll lost persisted outcome history")
    open.pressed.emit()
    _check(drawer.visible and not reroll.disabled,
        "Reroll of a percentile D100 must remain available for another round")
    var history_button := drawer.find_child("OpenFullPhysicalHistory",true,false) as Button
    if history_button != null:
        history_button.pressed.emit()
        await process_frame
        var dialog := scene.get("history_dialog") as AcceptDialog
        _check(dialog!=null and dialog.visible,
            "Player cannot open detailed local real-D100 source history")
        if dialog!=null:
            var details := dialog.find_child("ActualIndividualFacesAndRerolls",true,false) as RichTextLabel
            _check(details!=null and details.text.contains("реальные пары D10"),
                "Detailed history hides the original/new real percentile source pairs")
    print("M4_REAL_UI_PERCENTILE_PAIR_REROLL checks=%d failures=%d" % [
        checks,failures])
    quit(0 if failures==0 else 1)
