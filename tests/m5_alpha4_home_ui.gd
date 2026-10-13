extends SceneTree
## Alpha 4 live reference, translated to genuine offline Godot Jolt UI.
## Real visual 720x1280 and AVD input remain separate full Gauntlet gates.
var checks := 0
var failures := 0

func _initialize() -> void:
    call_deferred("_run")

func _check(ok: bool, detail: String) -> void:
    checks += 1
    if not ok:
        failures += 1
        push_error(detail)

func _run() -> void:
    root.size = Vector2i(720, 1280)
    var scene := load("res://src/main.tscn").instantiate() as Node3D
    root.add_child(scene)
    await process_frame
    await process_frame
    var overlay := scene.get_node_or_null("GameHUD/OverlayRoot") as Control
    _check(overlay != null, "Godot physical stage overlay absent")
    if overlay == null:
        quit(1)
        return
    var brand := overlay.get_node_or_null("AppTitle") as Label
    var strap := overlay.get_node_or_null("M5OfflineStudioCaption") as Label
    var tray := overlay.get_node_or_null("M5PhysicalTrayCaption") as Label
    var formula := overlay.get_node_or_null("M5LivePhysicalFormula") as Label
    var hamburger := overlay.get_node_or_null("OpenAdvancedRules") as Button
    var history := overlay.get_node_or_null("M5HistoryShortcut") as Button
    var composer := overlay.get_node_or_null("M5ComposeShortcut") as Button
    _check(brand != null and brand.text == "ADEL DICE ROLL",
        "Real Alpha4 brand is not in launch scene")
    _check(strap != null and "OFFLINE" in strap.text,
        "Personal offline Android must not advertise old online broadcast")
    _check(tray != null and tray.text == "ФИЗИЧЕСКИЙ ЛОТОК",
        "Physical tray semantic caption missing")
    _check(formula != null and formula.text == "1d6 · обычный",
        "Initial physical formula must match default actual D6")
    # Visual critic: original #38179746009 native-01-launch screenshot had
    # both texts drawn ON TOP of the showcased D20's bevel at y~=178.
    # Keep the lower edge of live formula ABOVE that authored 3D silhouette.
    _check(tray != null and tray.position.y <= 130.0,
        "Physical stage eyebrow overlaps the D20 hero die")
    _check(formula != null and formula.position.y <= 150.0,
        "Live formula overlays the D20 bevel in real original screenshot")
    _check(hamburger != null and history != null and composer != null,
        "Real menu, history and pool shortcuts required")
    if hamburger != null and history != null and composer != null:
        for button in [hamburger, history, composer]:
            var rect: Rect2 = button.get_global_rect()
            _check(rect.size.y >= 44.0 and rect.size.x >= 44.0,
                "Alpha4 header touch target too small")
            _check(rect.position.y >= 0.0 and rect.end.x <= 720.0,
                "Header button outside 720x1280 mobile scene")
        _check(not hamburger.get_global_rect().intersects(history.get_global_rect()),
            "Header menu overlaps history shortcut")
        _check(not composer.get_global_rect().intersects(history.get_global_rect()),
            "Compose shortcut overlaps history shortcut")
        history.pressed.emit()
        await process_frame
        var dialog := scene.get("history_dialog") as AcceptDialog
        _check(dialog != null and dialog.visible,
            "Real history shortcut must open existing offline history, not a placeholder")
        if dialog != null:
            dialog.hide()
        composer.pressed.emit()
        await process_frame
        var drawer := scene.get("advanced_panel") as PanelContainer
        var pool := drawer.get("pool_composer") as ConfirmationDialog
        _check(drawer.visible and pool.visible,
            "Compose shortcut must open real editable physical pool")
        pool.hide()
        drawer.visible = false
    scene.call("_select_die_type", 20)
    _check(formula != null and formula.text == "1d20 · обычный",
        "Hero formula does not follow actual physical die selection")
    scene.call("_select_die_type", 100)
    _check(formula != null and "2 × D10" in formula.text,
        "Initial two-physical-D10 mode not visible in hero")
    scene.call("_toggle_d100_mode")
    _check(formula != null and "1 × D100" in formula.text,
        "Actual single D100 mode not reflected in hero")
    print("M5_ALPHA4_HOME checks=%d failures=%d" % [checks, failures])
    scene.queue_free()
    quit(0 if failures == 0 else 1)
