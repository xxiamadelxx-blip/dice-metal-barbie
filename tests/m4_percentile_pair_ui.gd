extends SceneTree
## Real user button click on a paired percentile D100; do not substitute RNG.
var checks := 0
var failures := 0
func _initialize() -> void:
    call_deferred("_run")
func assert_real(cond: bool, message: String) -> void:
    checks += 1
    if not cond:
        failures += 1
        push_error(message)
func _settle(pool: Node3D) -> bool:
    for i in range(14500):
        await physics_frame
        if not bool(pool.get("busy")):
            return true
    return false
func _run() -> void:
    root.size=Vector2i(720,1280)
    var scene := load("res://src/main.tscn").instantiate() as Node3D
    root.add_child(scene)
    await process_frame
    var menu := scene.get_node_or_null("GameHUD/OverlayRoot/OpenAdvancedRules") as Button
    var drawer := scene.get("advanced_panel") as PanelContainer
    assert_real(menu != null and drawer != null,"Real approved hidden menu missing")
    if failures:
        quit(1)
        return
    menu.pressed.emit()
    var formula := drawer.get("formula_input") as LineEdit
    formula.text = "1d100+1d4-2"
    var option := drawer.get("hundred_modes") as OptionButton
    assert_real(option.selected == 0,"D100 should default to two REAL physical D10")
    var go := drawer.get("roll_button") as Button
    go.pressed.emit()
    var pool := scene.get("physical_pool") as Node3D
    assert_real(pool != null and bool(pool.get("busy")),
        "UI did not launch a genuine physical percentile pair")
    if pool == null:
        quit(1)
        return
    assert_real(await _settle(pool),"UI percentile pair did not settle")
    var first: Dictionary = pool.get("last_result")
    assert_real(bool(first.get("ok",false)),
        "No actual Jolt percentile pair from user-pressed button")
    if not bool(first.get("ok",false)):
        quit(1)
        return
    var bodies: Array = pool.get("_active")
    var kept_d4: RigidBody3D = bodies[2]
    var original_d4 := int(kept_d4.get("result"))
    var old_pair: Array = first["groups"][0]["percentile_source_d10_attempts"][0][0]
    menu.pressed.emit()
    var picker := drawer.find_child("ChoosePhysicalDieToReroll",true,false) as OptionButton
    var reroll := drawer.find_child("RerollChosenPhysicalDie",true,false) as Button
    assert_real(picker!=null and reroll!=null and not reroll.disabled,
        "Player cannot select the actual logical D100 2×D10 physical pair")
    if picker==null or reroll==null:
        quit(1)
        return
    assert_real(picker.get_item_text(0).contains("D100"),
        "Reroll choice must visibly identify D100 as TWO real D10 bodies")
    picker.select(0)
    reroll.pressed.emit()
    assert_real(bool(pool.get("busy")) and not drawer.visible,
        "True physical percentile UI reroll did not start")
    assert_real(await _settle(pool),"Real UI-selected D100 pair reroll hung")
    var result: Dictionary = pool.get("last_result")
    assert_real(bool(result.get("ok",false)),
        "User-clicked D100 reroll did not deliver two genuine upper faces")
    if bool(result.get("ok",false)):
        var pairs: Array = result["groups"][0]["percentile_source_d10_attempts"][0]
        assert_real(pairs.size()==2 and pairs[0]==old_pair,
            "Player-visible D100 reroll lost the old physical source pair")
        assert_real(int(result.get("reroll_source_body_count",0))==2,
            "User-selected logical D100 didn't physically roll two D10")
        assert_real(kept_d4.freeze and int(kept_d4.get("result"))==original_d4,
            "Player-selected D100 moved the unselected real D4")
        assert_real(int(scene.get("last_result"))==int(result["total"]),
            "Player HUD not updated from physically measured percentile pair")
    var history: Array = scene.get("roll_store").call("snapshot")["history"]
    assert_real(not history.is_empty() and
        history[0]["groups"][0]["percentile_source_d10_attempts"][0].size()==2,
        "Offline real UI history didn't keep two separate D10 source attempts")
    print("M4_REAL_PAIR_UI QA %d checks / %d failures" % [checks,failures])
    quit(0 if failures==0 else 1)
