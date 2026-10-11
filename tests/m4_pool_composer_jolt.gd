extends SceneTree
## Actual panel/player buttons + true Jolt physical mixed groups; pure builder
## cases are synthetic specifications ONLY, never saved as real outcomes.
const Builder = preload("res://src/core/roll_pool_builder.gd")
const Formula = preload("res://src/core/roll_formula.gd")
var checks := 0
var failures := 0

func _initialize() -> void:
    call_deferred("_run")

func _check(condition: bool, message: String) -> void:
    checks += 1
    if not condition:
        failures += 1
        push_error(message)

func _wait(pool: Node3D) -> bool:
    for tick in range(12000):
        await physics_frame
        if not bool(pool.get("busy")):
            return true
    return false

func _run() -> void:
    var source: RefCounted = Builder.new()
    _check(bool(source.call("load_formula","1d6+1d4-3")),
        "Builder cannot parse approved original formula")
    _check(not bool(source.call("load_formula","bad+d37")) and
        str(source.call("current_formula"))=="1d6+1d4-3",
        "Invalid free-text may not destroy previously loaded model")
    _check(bool(source.call("adjust_count",0,1)) and
        str(source.call("current_formula"))=="2d6+1d4-3",
        "Adding a REAL D6 must update count in same group")
    _check(bool(source.call("change_sign",1)) and
        str(source.call("current_formula"))=="2d6-1d4-3",
        "Negative groups must preserve physical signed arithmetic")
    _check(bool(source.call("add_group",20)) and
        bool(source.call("adjust_modifier",1)) and
        str(source.call("current_formula"))=="2d6-1d4+1d20-2",
        "Adding selected D20 / positive modifier must round-trip")
    _check(not bool(source.call("add_group",37)) and
        not bool(source.call("adjust_count",0,64)),
        "Unsupported D37 and >64 physical bodies must be refused")
    _check(str(source.call("current_formula"))=="2d6-1d4+1d20-2",
        "Rejected operation partially changed active composition")
    _check(bool(source.call("load_formula","64d6")) and
        not bool(source.call("add_group",4)),
        "Physical group addition may not exceed 64 total bodies")
    _check(bool(source.call("load_formula","1d6")) and
        not bool(source.call("remove_group",0)),
        "Last remaining die group cannot be removed")
    _check(bool(source.call("load_formula",
        "1d4+1d6+1d8+1d10+1d12+1d20+1d100+1d4+1d6+1d8+1d10+1d12")) and
        not bool(source.call("add_group",6)),
        "12-group ceiling is required by the core formula parser")
    _check(bool(source.call("load_formula","1d100+1d6")) and
        str(source.call("current_formula"))=="1d100+1d6",
        "Both approved physical D100 modes need untouched expression syntax")

    root.size=Vector2i(720,1280)
    var scene := load("res://src/main.tscn").instantiate() as Node3D
    root.add_child(scene)
    await process_frame
    var open := scene.get_node_or_null(
        "GameHUD/OverlayRoot/OpenAdvancedRules") as Button
    var panel := scene.get("advanced_panel") as PanelContainer
    _check(open!=null and panel!=null and not panel.visible,
        "App must hide advanced pool builder by default")
    if panel==null or open==null:
        quit(1)
        return
    open.pressed.emit()
    var trigger := panel.find_child("OpenPhysicalPoolComposer",true,false) as Button
    var formula := panel.get("formula_input") as LineEdit
    var dialog := panel.get("pool_composer") as ConfirmationDialog
    _check(trigger!=null and dialog!=null and formula!=null,
        "Player pool controls must exist in actual Godot drawer")
    if trigger==null or dialog==null or formula==null:
        quit(1)
        return
    formula.text = "1d6+1d4-3"
    trigger.pressed.emit()
    await process_frame
    _check(dialog.visible,"Click on НАБОР must open actual composer modal")
    # A green click test is insufficient if the real 720x1280 GUI clips
    # the action buttons. Validate modal Window geometry independently.
    var popup_screen: Vector2i = dialog.size
    _check(popup_screen.y <= 750 and popup_screen.y >= 620,
        "Pool composer exceeded actual mobile viewport: "+str(popup_screen))
    var actual_apply: Button=dialog.get_ok_button()
    _check(actual_apply!=null and actual_apply.get_global_rect().end.y <= 800,
        "Real APPLY button fell below the intended mobile dialog")
    var list := dialog.find_child("EditablePhysicalGroups",true,false) as ItemList
    var increase := dialog.find_child("IncreaseGroupCount",true,false) as Button
    var change_sign := dialog.find_child("FlipGroupSign",true,false) as Button
    var add := dialog.find_child("AddPhysicalGroup",true,false) as Button
    var die_choice := dialog.find_child("ChooseGroupDieType",true,false) as OptionButton
    var modifier_plus := dialog.find_child("IncreasePoolModifier",true,false) as Button
    var preview := dialog.find_child("PhysicalPoolFormulaPreview",true,false) as Label
    _check(list!=null and increase!=null and change_sign!=null and add!=null
        and die_choice!=null and modifier_plus!=null and preview!=null,
        "Actual buttons/selection/preview missing from GUI")
    if add!=null and increase!=null and preview!=null:
        _check(add.get_global_rect().end.y<750 and
            increase.get_global_rect().end.y<750 and
            preview.get_global_rect().end.y<750,
            "Scroll list enlarged past real selectable editing controls")
    if list==null or increase==null or change_sign==null or add==null or (
            die_choice==null or modifier_plus==null or preview==null):
        quit(1)
        return
    increase.pressed.emit()
    list.select(1)
    list.item_selected.emit(1)
    change_sign.pressed.emit()
    for i in range(die_choice.item_count):
        if die_choice.get_item_id(i)==20:
            die_choice.select(i)
            break
    add.pressed.emit()
    modifier_plus.pressed.emit()
    modifier_plus.pressed.emit()
    _check(preview.text.contains("2d6-1d4+1d20-1") and list.item_count==3,
        "Real clicked composer did not assemble 3 signed groups and modifier")
    _check(formula.text=="1d6+1d4-3",
        "Edits MUST remain private until player confirms; cancel is safe")
    # Real OK button uses the ConfirmationDialog signal; this is an actual
    # Godot control, not an artificial setting of the expression.
    dialog.get_ok_button().pressed.emit()
    _check(formula.text=="2d6-1d4+1d20-1",
        "Real apply button did not update the existing formula input")
    _check(bool(Formula.parse(formula.text).get("ok",false)),
        "Player-assembled expression failed core grammar validation")
    var launch := panel.get("roll_button") as Button
    var store := scene.get("roll_store") as RefCounted
    var history_before: Array = store.call("snapshot")["history"]
    launch.pressed.emit()
    var pool := scene.get("physical_pool") as Node3D
    _check(pool!=null and bool(pool.get("busy")) and not panel.visible,
        "Actual assembled pool must start real locked Jolt throw")
    if pool==null:
        quit(1)
        return
    _check(await _wait(pool),"Four real signed-group rigid bodies never settled")
    var result: Dictionary = pool.get("last_result")
    _check(bool(result.get("ok",false)) and
        str(result.get("formula",""))=="2d6-1d4+1d20-1",
        "Jolt outcome lost exact source player-composed expression")
    if bool(result.get("ok",false)):
        var body_count: int=(pool.get("_active") as Array).size()
        _check(body_count==4 and int(pool.get("peak_simultaneously_rolling"))>=2,
            "Four real physical dice did not participate in actual throw")
        var actual_sum:=int(result.get("modifier",9999))
        for group in (result["groups"] as Array):
            actual_sum+=int((group as Dictionary)["subtotal"])
        _check(actual_sum==int(result["total"]) and
            int(scene.get("last_result"))==actual_sum,
            "Selected physical upper faces diverged from signed formula total")
    var saved: Array=store.call("snapshot")["history"]
    _check(saved.size()==mini(history_before.size()+1,200) and
        str(saved[0].get("formula",""))=="2d6-1d4+1d20-1",
        "Real player-built Jolt roll not persisted under exact formula")
    open.pressed.emit()
    formula.text="invalid+d37"
    trigger.pressed.emit()
    _check(not dialog.visible and formula.text=="invalid+d37",
        "Malformed free-text opened editor and fabricated a replacement formula")
    print("M4_ACTUAL_POOL_COMPOSER_JOLT checks=%d failures=%d" % [checks,failures])
    quit(0 if failures==0 else 1)
