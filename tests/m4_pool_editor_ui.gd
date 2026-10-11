extends SceneTree
## UI-driven M4 group editor + one genuine Jolt physical throw.
## No fixed/counterfeit physical faces or simulated histories.
const Formula = preload("res://src/core/roll_formula.gd")
var checked := 0
var failed := 0

func _initialize() -> void:
    call_deferred("_run")

func _check(ok: bool,why: String) -> void:
    checked += 1
    if not ok:
        failed += 1
        push_error(why)

func _await_pool(pool: Node3D) -> bool:
    for tick in range(15000):
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
    var open := scene.get_node("GameHUD/OverlayRoot/OpenAdvancedRules") as Button
    open.pressed.emit()
    var button := panel.find_child("EditPhysicalPool",true,false) as Button
    _check(button!=null and panel.visible,"Hidden M4 menu must provide actual pool editor")
    if button==null:
        quit(1)
        return
    var formula := panel.get("formula_input") as LineEdit
    _check(formula.text=="2d6+1d20-3","Initial manual formula unexpectedly modified")
    button.pressed.emit()
    var editor := panel.get("pool_editor") as ConfirmationDialog
    _check(editor!=null and editor.visible,"Real editor dialog not opened")
    if editor==null:
        quit(1)
        return
    _check((editor.get("draft_groups") as Array).size()==2 and
        int(editor.get("draft_modifier"))==-3,
        "Did not parse manually authored groups and modifier")
    var list := editor.find_child("EditableDiceGroups",true,false) as ItemList
    var plus := editor.find_child("PoolOneDieMore",true,false) as Button
    var minus := editor.find_child("PoolOneDieLess",true,false) as Button
    var sign := editor.find_child("NewGroupSign",true,false) as OptionButton
    var die := editor.find_child("ChooseDieForPool",true,false) as OptionButton
    var add := editor.find_child("AddDieToPool",true,false) as Button
    var mplus := editor.find_child("PoolModifierPlus",true,false) as Button
    var remove := editor.find_child("RemoveDieFromPool",true,false) as Button
    _check(list!=null and plus!=null and minus!=null and sign!=null and
        die!=null and add!=null and mplus!=null and remove!=null,
        "Real controls for count/sign/add/remove/modifier missing")
    if failed>0:
        quit(1)
        return
    _check(str(editor.call("composed_expression"))=="2d6+1d20-3",
        "Formula was changed by opening editor")
    plus.pressed.emit()
    _check(str(editor.call("composed_expression"))=="3d6+1d20-3",
        "Pressing count +1 must update the FIRST actual source group")
    minus.pressed.emit()
    _check(str(editor.call("composed_expression"))=="2d6+1d20-3",
        "Count -1 must reverse the first change")
    die.select(0)
    sign.select(1)
    add.pressed.emit()
    _check(str(editor.call("composed_expression"))=="2d6+1d20-1d4-3",
        "Signed D4 must be added to the mixed physical pool")
    mplus.pressed.emit()
    _check(str(editor.call("composed_expression"))=="2d6+1d20-1d4-2",
        "Modifier stepper must preserve signed groups")
    var parsed: Dictionary = Formula.parse(str(editor.call("composed_expression")))
    _check(bool(parsed.get("ok",false)) and
        int(parsed.get("physical_dice",0))==4 and
        (parsed["groups"] as Array).size()==3,
        "Editor formula must remain a real parseable four-Jolt-body group")
    # Attempting to delete the ONLY remaining group must never forge 0 dice.
    _check(bool(editor.call("load_expression","1d6")),
        "Read-only editor fixture cannot load valid single die")
    remove.pressed.emit()
    _check(str(editor.call("composed_expression"))=="1d6",
        "UI allowed deleting last real die")
    # Cancel is non-destructive. Both the published formula and physics
    # must remain exactly what they were before entering this dialog.
    editor.canceled.emit()
    editor.hide()
    _check(formula.text=="2d6+1d20-3","Cancel changed user formula")
    button.pressed.emit()
    _check(bool(editor.visible),"Could not reopen editor after cancel")
    _check(bool(editor.call("load_expression","2d6+1d20-1d4-2")),
        "Cannot open edited legal mixed-pool formula")
    editor.confirmed.emit()
    editor.hide()
    _check(formula.text=="2d6+1d20-1d4-2",
        "Apply must publish exact validated editor formula to real player HUD")
    var roll := panel.get("roll_button") as Button
    roll.pressed.emit()
    var pool := scene.get("physical_pool") as Node3D
    _check(pool!=null and bool(pool.get("busy")) and not panel.visible,
        "New pool formula must start GENUINE Godot/Jolt and hide drawer")
    _check(button.disabled,"Pool editor must lock during physical throw")
    if pool==null:
        quit(1)
        return
    _check(await _await_pool(pool),"Four real physical dice failed to settle")
    var result: Dictionary = pool.get("last_result")
    _check(bool(result.get("ok",false)) and
        str(result.get("formula",""))=="2d6+1d20-1d4-2",
        "Godot settled result not based on submitted editor formula")
    if bool(result.get("ok",false)):
        var sum := int(result["modifier"])
        var bodies := 0
        for group in (result["groups"] as Array):
            sum += int(group["subtotal"])
            bodies += (group["kept_faces"] as Array).size()
        _check(sum==int(result["total"]) and bodies==4,
            "Signed total must equal actual physical faces of four dice")
    var store := scene.get("roll_store") as RefCounted
    var history: Array = store.call("snapshot")["history"]
    _check(not history.is_empty() and
        str(history[0].get("formula",""))=="2d6+1d20-1d4-2",
        "New player editor result did not persist in offline history")
    _check(not button.disabled,"Editor must unlock after all physical bodies settle")
    print("M4_REAL_EDITABLE_POOL_UI checks=%d failures=%d" % [checked,failed])
    quit(0 if failed==0 else 1)
