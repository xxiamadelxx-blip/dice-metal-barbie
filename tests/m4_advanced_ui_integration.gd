extends SceneTree
## Real full Godot mobile HUD interaction + true Jolt multi-body physical outcome.
const Formula = preload("res://src/core/roll_formula.gd")
var checked := 0
var failed := 0

func _initialize() -> void:
    call_deferred("_run")

func _check(good: bool, what: String) -> void:
    checked += 1
    if not good:
        failed += 1
        push_error(what)

func _wait(pool: Node3D) -> bool:
    for i in range(15000):
        await physics_frame
        if not bool(pool.get("busy")):
            return true
    return false

func _run() -> void:
    root.size = Vector2i(720,1280)
    var scene := load("res://src/main.tscn").instantiate() as Node3D
    root.add_child(scene)
    await process_frame
    var panel := scene.get("advanced_panel") as PanelContainer
    var store := scene.get("roll_store") as RefCounted
    var open := scene.get_node_or_null("GameHUD/OverlayRoot/OpenAdvancedRules") as Button
    _check(panel != null and open != null and store != null,
        "Actual advanced UX/persistence controls missing")
    if failed > 0:
        quit(1)
        return
    _check(not panel.visible,"Advanced UI MUST start hidden")
    open.pressed.emit()
    _check(panel.visible,"Hamburger must open the actual advanced controls")
    var formula := panel.get("formula_input") as LineEdit
    var title := panel.get("name_input") as LineEdit
    var submit := panel.get("roll_button") as Button
    _check(formula != null and title != null and submit != null,"M4 editing inputs missing")
    if failed > 0:
        quit(1)
        return
    formula.text = "1d6+1d4-3"
    title.text = "Проверка М4"
    var save := panel.find_child("SaveNamedPreset",true,false) as Button
    var apply := panel.find_child("ApplySavedPreset",true,false) as Button
    _check(save != null and apply != null,"Real preset controls missing")
    if failed > 0:
        quit(1)
        return
    save.pressed.emit()
    var presets: Dictionary = store.call("snapshot")["presets"]
    _check(presets.has("Проверка М4"),"User click did not persist named preset")
    formula.text = "1d20"
    apply.pressed.emit()
    _check(formula.text == "1d6+1d4-3",
        "Apply preset did not restore saved real formula")
    var before: int = (store.call("snapshot")["history"] as Array).size()
    submit.pressed.emit()
    var pool := scene.get("physical_pool") as Node3D
    _check(pool != null and bool(pool.get("busy")),
        "UI click must launch real Jolt physical pool")
    _check(not panel.visible and open.disabled,
        "During active Jolt animation the advanced drawer must close and lock")
    if pool == null:
        quit(1)
        return
    var resolved := await _wait(pool)
    _check(resolved,"Physical mixed UI throw never finished")
    _check(pool.get("last_physical_error") == "",
        "Jolt failed through UI: "+str(pool.get("last_physical_error")))
    var result: Dictionary = pool.get("last_result")
    _check(bool(result.get("ok",false)),"Mixed UI produced no real face result")
    if bool(result.get("ok",false)):
        var actual_faces: Array = result["groups"]
        var calculated := int(result["modifier"])
        for group in actual_faces:
            calculated += int(group["subtotal"])
        _check(calculated == int(result["total"]),
            "UI physical sum diverges from source faces")
        _check(result["formula"] == "1d6+1d4-3",
            "User-visible formula changed during physical throw")
        _check(int(scene.get("last_result")) == int(result["total"]),
            "Visible UI result differs from real Jolt sum")
        _check(not submit.disabled,
            "Advanced UI must re-enable after physical settlement")
    _check(not open.disabled and not submit.disabled,
        "After completed Jolt roll advanced controls must unlock")
    open.pressed.emit()
    _check(panel.visible, "Saved history drawer must reopen after physics")
    var previous_result := int(scene.get("last_result"))
    formula.text = "broken+d37"
    submit.pressed.emit()
    _check(int(scene.get("last_result")) == previous_result and panel.visible,
        "Invalid advanced formula erased previous true physical result/table")
    var after: Array = store.call("snapshot")["history"]
    _check(after.size() == mini(before+1,200),
        "Actual real-body user throw was not persisted in history")
    if not after.is_empty():
        _check(after[0]["total"] == result.get("total"),
            "Stored result does not match Jolt UI real physical value")
    var new_store=load("res://src/core/roll_persistence.gd").new()
    _check(new_store.load_state().get("ok",false),
        "Offline user history could not be reopened after real physical throw")
    _check((new_store.snapshot()["history"] as Array).size() == after.size(),
        "User physical history not durable across scene reload")
    # No forced cinematic result, all physical bodies must genuinely settle.
    print("M4_ANDROID_HUD_PHYSICAL_INTERACTION checks=%d failures=%d" %
        [checked,failed])
    quit(0 if failed == 0 else 1)
