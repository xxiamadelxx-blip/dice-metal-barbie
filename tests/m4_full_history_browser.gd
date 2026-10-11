extends SceneTree
const Formula = preload("res://src/core/roll_formula.gd")
## Real Godot scene and real Jolt physical roll drive fully scrollable,
## offline detailed history. No fabricated player outcomes are inserted.
var checks := 0
var failed := 0

func _initialize() -> void:
    call_deferred("_run")
func _check(valid: bool, message: String) -> void:
    checks += 1
    if not valid:
        failed += 1
        push_error(message)
func _wait(roll_pool: Node3D) -> bool:
    for tick in range(12000):
        await physics_frame
        if not bool(roll_pool.get("busy")):
            return true
    return false

func _run() -> void:
    root.size=Vector2i(720,1280)
    var scene := load("res://src/main.tscn").instantiate() as Node3D
    root.add_child(scene)
    await process_frame
    var trigger := scene.get_node_or_null("GameHUD/OverlayRoot/OpenAdvancedRules") as Button
    var panel := scene.get("advanced_panel") as PanelContainer
    var history_button := panel.find_child("OpenFullPhysicalHistory",true,false) as Button
    _check(trigger!=null and history_button!=null,
        "M4 full history button not exposed in the actual drawer")
    if failed>0:
        quit(1)
        return
    trigger.pressed.emit()
    var input := panel.get("formula_input") as LineEdit
    input.text="2d6+1d20-3"
    var throw_button := panel.get("roll_button") as Button
    throw_button.pressed.emit()
    var pool := scene.get("physical_pool") as Node3D
    _check(pool!=null and bool(pool.get("busy")),
        "Real source Jolt die roll not started")
    if pool==null:
        quit(1)
        return
    _check(await _wait(pool),"First real composed roll never ended")
    var original: Dictionary = pool.get("last_result")
    _check(bool(original.get("ok",false)),"Original upper-face result absent")
    if failed>0:
        quit(1)
        return
    var first: int = int(original["groups"][0]["kept_faces"][0])
    trigger.pressed.emit()
    var pick := panel.find_child("ChoosePhysicalDieToReroll",true,false) as OptionButton
    var reroll := panel.find_child("RerollChosenPhysicalDie",true,false) as Button
    _check(pick!=null and reroll!=null and not reroll.disabled,
        "Real history fixture must offer an actually rolled source D6")
    if reroll==null:
        quit(1)
        return
    reroll.pressed.emit()
    _check(await _wait(pool),"Actual selected D6 Jolt reroll timed out")
    var updated: Dictionary = pool.get("last_result")
    _check(bool(updated.get("ok",false)),"Actual Jolt reroll missing after UI click")
    if failed>0:
        quit(1)
        return
    var trace: Array = updated["groups"][0]["attempts"][0]
    _check(trace.size()==2 and int(trace[0])==first,
        "Real original/updated physical face trace was not preserved")
    trigger.pressed.emit()
    history_button.pressed.emit()
    await process_frame
    var dialog := scene.get("history_dialog") as AcceptDialog
    _check(dialog!=null and dialog.visible,
        "Actually clicked history viewer did not open its window")
    if dialog==null:
        quit(1)
        return
    var store: RefCounted = scene.get("roll_store")
    var state: Dictionary = store.call("snapshot")
    var saved: Array = state["history"]
    _check(dialog.call("visible_record_count")==saved.size(),
        "Full history omitted physical records or showed only last two")
    var list := dialog.find_child("AllSavedRolls",true,false) as ItemList
    var search := dialog.find_child("SearchPhysicalRollHistory",true,false) as LineEdit
    var detail := dialog.find_child("ActualIndividualFacesAndRerolls",true,false) as RichTextLabel
    _check(list!=null and search!=null and detail!=null,
        "Real scrollable list/search/individual-face details not available")
    if failed>0:
        quit(1)
        return
    _check(list.item_count==saved.size(),
        "Actual 200-entry-compatible history list lost offline records")
    _check(dialog.call("selected_record_index")==0,
        "History did not select latest physically verified outcome")
    _check(detail.text.contains("Кубик 1") and
        detail.text.contains("физический переброс") and
        detail.text.contains(" → "),
        "Full history detail did not display both true source faces")
    var newest := str(updated["formula"])
    _check(detail.text.contains(newest) and
        detail.text.contains(str(updated["total"])),
        "Detail browser does not show the original real formula/total")
    search.text = "THIS_WILL_MATCH_NO_PHYSICAL_ROLL"
    search.text_changed.emit(search.text)
    _check(int(dialog.call("visible_record_count"))==0,
        "History search does not narrow to zero matches")
    search.text=newest
    search.text_changed.emit(search.text)
    _check(int(dialog.call("visible_record_count"))>=1,
        "History search failed to find the source formula")
    # UI-only oracle: no fabricated roll is saved or portrayed as real.
    # Check the selected *physical D20 source*, not simply first D20 item.
    var advantage: Dictionary = Formula.evaluate(
        Formula.parse("1d20+2"),[[3,18]],"advantage")
    _check(bool(advantage.get("ok",false)),
        "Deterministic history-display oracle for D20 advantage failed")
    # The preceding positive search filtered by a different formula.
    # Clear that filter before switching to explicit display-only oracles.
    search.text = ""
    search.text_changed.emit(search.text)
    dialog.call("set_history",[advantage])
    _check(detail.text.contains("Кубик 1: 3  ·  засчитано: (не выбран)") and
        detail.text.contains("Кубик 2: 18  ·  засчитано: 18"),
        "History wrong: must mark actually kept advantage D20 die #2: "+detail.text)
    var disadvantage: Dictionary = Formula.evaluate(
        Formula.parse("1d20+2"),[[3,18]],"disadvantage")
    dialog.call("set_history",[disadvantage])
    _check(detail.text.contains("Кубик 1: 3  ·  засчитано: 3") and
        detail.text.contains("Кубик 2: 18  ·  засчитано: (не выбран)"),
        "History wrong: must mark kept disadvantage D20 die #1: "+detail.text)
    # Read-only display oracle: user-visible source D10 chronology. Test
    # numbers are NOT claimed as actual physical throws or saved to disk.
    var paired: Dictionary = Formula.evaluate(Formula.parse("1d100+1d6"),
        [[{"states":[[4,1],[8,1],[8,10]]}],[3]])
    _check(bool(paired.get("ok",false)),"Paired D100 view fixture invalid")
    dialog.call("set_history",[paired])
    _check(detail.text.contains("41 → 81 → 80") and
        detail.text.contains("4/1 → 8/1 → 8/10") and
        detail.text.contains("десятки/единицы"),
        "Full history hides original/intermediate/final source D10 faces: "+detail.text)
    # View must remain non-destructive for actual previous Jolt data.
    _check((store.call("snapshot")["history"] as Array).size()==saved.size(),
        "Displaying pair source chronology changed real stored history")
    # Screen-render load test: repeat a COPY of an actually tested source
    # record to reach 200 rows. This only stress-tests the UI; these are NOT
    # 200 claimed independent physical throws and are NEVER persisted.
    var stress_rows: Array = []
    for i in range(200):
        stress_rows.append(saved[0].duplicate(true))
    search.text = ""
    dialog.call("set_history",stress_rows)
    _check(int(dialog.call("visible_record_count"))==200 and list.item_count==200,
        "History cannot display all 200 allowed records")
    list.select(199)
    dialog.call("_choose_visible_row",199)
    _check(int(dialog.call("selected_record_index"))==199,
        "History cannot inspect the oldest retained record #200")
    dialog.call("set_history",saved)
    var reread: Dictionary = store.call("snapshot")
    _check((reread["history"] as Array).size()==saved.size(),
        "Readonly history browsing/search accidentally modified stored data")
    dialog.hide()
    _check(not dialog.visible,"History close must restore focus to dice")
    print("M4_REAL_UI_ALL_HISTORY checks=%d failures=%d records=%d" %
        [checks,failed,saved.size()])
    quit(0 if failed==0 else 1)
