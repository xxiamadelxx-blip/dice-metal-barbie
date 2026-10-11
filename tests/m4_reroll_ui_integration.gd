extends SceneTree
## Authentic M4 UI reroll click drives a selected physical Jolt source body;
## untouched dice keep their visible actual faces and offline history replays
## both natural source faces (never a virtual replacement outcome).
var checks := 0
var failures := 0

func _initialize() -> void:
    call_deferred("_run")
func _check(ok: bool, reason: String) -> void:
    checks += 1
    if not ok:
        failures += 1
        push_error(reason)
func _wait(pool: Node3D) -> bool:
    for tick in range(12000):
        await physics_frame
        if not bool(pool.get("busy")):
            return true
    return false

func _run() -> void:
    root.size=Vector2i(720,1280)
    var scene := load("res://src/main.tscn").instantiate() as Node3D
    root.add_child(scene)
    await process_frame
    var open: Button = scene.get_node_or_null("GameHUD/OverlayRoot/OpenAdvancedRules")
    var panel := scene.get("advanced_panel") as PanelContainer
    _check(open != null and panel != null,"Actual advanced M4 menu missing")
    if failures > 0:
        quit(1)
        return
    open.pressed.emit()
    var formula := panel.get("formula_input") as LineEdit
    formula.text = "2d6+1d20-3"
    var thrower := panel.get("roll_button") as Button
    thrower.pressed.emit()
    var pool: Node3D = scene.get("physical_pool") as Node3D
    _check(pool!=null and bool(pool.get("busy")),
        "Real M4 compose button failed to launch source rigid bodies")
    if pool == null:
        quit(1)
        return
    _check(await _wait(pool),"First actual physical pool did not finish")
    var first: Dictionary = pool.get("last_result")
    _check(bool(first.get("ok",false)),"First real mixed Jolt pool invalid")
    if failures > 0:
        quit(1)
        return
    var bodies: Array = pool.get("_active")
    _check(bodies.size()==3,"Expected 2 D6 and one D20 genuinely on table")
    var d6_kept: RigidBody3D = bodies[1]
    var d20_kept: RigidBody3D = bodies[2]
    var first_original_face: int = int(bodies[0].get("result"))
    var kept6: int = int(d6_kept.get("result"))
    var kept20: int = int(d20_kept.get("result"))
    var store: RefCounted = scene.get("roll_store")
    var before: Array = store.call("snapshot")["history"]
    _check(not open.disabled,"Drawer did not unlock after completed physical pool")
    open.pressed.emit()
    _check(panel.visible,"Cannot reopen real reroll and history drawer")
    var selector := panel.find_child("ChoosePhysicalDieToReroll",true,false) as OptionButton
    var reroll := panel.find_child("RerollChosenPhysicalDie",true,false) as Button
    _check(selector!=null and reroll!=null and not reroll.disabled,
        "Actual physical die picker/reroll button missing or disabled")
    if selector==null or reroll==null:
        quit(1)
        return
    var index: int = selector.selected
    _check(index==0,"Expected first listed real source die selected")
    reroll.pressed.emit()
    _check(bool(pool.get("busy")) and not panel.visible,
        "Click must reroll one actual Jolt die and hide obstructing drawer")
    _check(await _wait(pool),"Real die reroll from UI never finished")
    var second: Dictionary = pool.get("last_result")
    _check(bool(second.get("ok",false)),"UI reroll yielded no valid physical source")
    if bool(second.get("ok",false)):
        _check((pool.get("_active") as Array).size()==3,
            "UI reroll removed other real rigid bodies from scene")
        _check(d6_kept.freeze and d20_kept.freeze,
            "Other selected sources must remain visibly held in position")
        _check(int(d6_kept.get("result"))==kept6 and
            int(d20_kept.get("result"))==kept20,
            "Physical reroll altered another die's real face")
        var source_series: Array = second["groups"][0]["attempts"][0]
        _check(source_series.size()==2 and int(source_series[0])==first_original_face,
            "User click did not preserve original physical top face")
        _check(int(source_series[-1])==int(bodies[0].get("result")),
            "Reroll history new upper face not physically visible")
        var computed := int(second["modifier"])
        for group in second["groups"]:
            computed += int(group["subtotal"])
        _check(computed == int(second["total"]),
            "User reroll updated a number without actual source arithmetic")
        _check(int(scene.get("last_result"))==int(second["total"]),
            "Player visible reroll total differs from real top faces")
    var after: Array = store.call("snapshot")["history"]
    _check(after.size()==mini(before.size()+1,200),
        "User reroll did not write new versioned offline history record")
    if not after.is_empty() and bool(second.get("ok",false)):
        _check(after[0]["groups"][0]["attempts"][0].size()==2 and
            int(after[0]["total"])==int(second["total"]),
            "Persisted reroll lost initial/new genuine source faces")
    open.pressed.emit()
    _check(panel.visible and not reroll.disabled,
        "Cannot view/choose saved physical source again after completion")
    # The previous real D6 flow leaves this drawer open.
    _check(panel.visible,"Cannot use existing advanced drawer for paired D100")
    formula.text = "1d100+1d6"
    thrower.pressed.emit()
    pool = scene.get("physical_pool") as Node3D
    _check(pool!=null and bool(pool.get("busy")),
        "Actual pair+D6 button failed to start Jolt")
    if pool==null:
        quit(1)
        return
    _check(await _wait(pool),"Player's two physical D10 did not settle")
    var original_pair: Dictionary = pool.get("last_result")
    _check(bool(original_pair.get("ok",false)),
        "Player D100 pair returned no verified Jolt result")
    if bool(original_pair.get("ok",false)):
        var source_bodies: Array = pool.get("_active")
        _check(source_bodies.size()==3,"Paired D100+D6 requires 3 physical sources")
        if source_bodies.size()==3:
            var tens: RigidBody3D=source_bodies[0]
            var ones: RigidBody3D=source_bodies[1]
            var other: RigidBody3D=source_bodies[2]
            var original_digits: Array=original_pair["groups"][0]["percentile_source_d10_faces"][0]
            var original_d6:=int(other.get("result"))
            for digit in ["tens","ones"]:
                open.pressed.emit()
                _check(panel.visible,"Drawer did not reopen for paired source picker")
                var choices: Array=panel.get("reroll_slots")
                var pair_item: int=0 if digit=="tens" else 1
                _check(choices.size()>=3 and choices[pair_item].get("digit","")==digit,
                    "Separate selectable physical tens/ones missing from real UI")
                selector.select(pair_item)
                reroll.pressed.emit()
                _check(bool(pool.get("busy")) and not panel.visible,
                    "Chosen physical percentile D10 was not launched by the UI")
                _check(await _wait(pool),"Player-selected physical D10 did not settle")
                var live: Dictionary=pool.get("last_result")
                _check(bool(live.get("ok",false)),
                    "Player-selected percentile D10 has no authentic face")
                if not bool(live.get("ok",false)):
                    break
                var steps: Array=live["groups"][0]["percentile_source_d10_attempts"][0]
                _check(steps.size()==(2 if digit=="tens" else 3),
                    "Percentile chronological trace was truncated")
                _check(int(steps[0][0])==int(original_digits[0]) and
                    int(steps[0][1])==int(original_digits[1]),
                    "Original physical digits lost after player UI reroll")
                var final_digits: Array=steps[-1]
                _check(int(final_digits[0])==int(tens.get("result")) and
                    int(final_digits[1])==int(ones.get("result")),
                    "Offline source faces do not match original live rigid bodies")
                _check(int(other.get("result"))==original_d6,
                    "Reroll silently changed a different genuine physical source")
                _check(live.get("rerolled_percentile_digit","")==digit and
                    int(scene.get("last_result"))==int(live["total"]),
                    "Displayed result or selected D10 metadata wrong")
                var history: Array=store.call("snapshot")["history"]
                _check(not history.is_empty() and
                    history[0]["groups"][0]["percentile_source_d10_attempts"][0].size()==steps.size(),
                    "Actual player reroll not recorded in full offline source history")
            open.pressed.emit()
            _check(panel.visible,"Cannot reopen full real D100 history")
            var history_button:=panel.find_child("OpenFullPhysicalHistory",true,false) as Button
            _check(history_button!=null,"Full history button missing")
            if history_button!=null:
                history_button.pressed.emit()
                var view:=scene.get("history_dialog") as AcceptDialog
                _check(view!=null and view.visible,"User-facing pair-D100 history did not open")
                if view!=null:
                    var detail:=view.find_child("ActualIndividualFacesAndRerolls",true,false) as RichTextLabel
                    _check(detail!=null and detail.text.contains("десятки/единицы"),
                        "Real player's complete pair history omitted tens/ones chronology")
    print("M4_ACTUAL_UI_SELECTED_JOLT_REROLL checks=%d failures=%d" %
        [checks,failures])
    quit(0 if failures==0 else 1)
