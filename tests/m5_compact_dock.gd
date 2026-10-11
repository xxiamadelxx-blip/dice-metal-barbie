extends SceneTree
## Actual Godot 720x1280 Control geometry, not mocked Android taps.
## The AVD job separately touches real selector pixels, completes Jolt throws.
var checks := 0
var failures := 0

func _initialize() -> void:
    call_deferred("_run")

func _check(ok: bool, msg: String) -> void:
    checks += 1
    if not ok:
        failures += 1
        push_error(msg)

func _run() -> void:
    root.size = Vector2i(720, 1280)
    var scene := load("res://src/main.tscn").instantiate() as Node3D
    root.add_child(scene)
    await process_frame
    await process_frame
    var hud := scene.get_node_or_null("GameHUD/OverlayRoot") as Control
    var dock := scene.get_node_or_null("GameHUD/OverlayRoot/ControlDock") as PanelContainer
    _check(hud != null and dock != null, "Real Godot bottom dock not found")
    if hud == null or dock == null:
        quit(1)
        return
    var dock_bounds: Rect2 = dock.get_global_rect()
    var row := dock.find_child("DiceTypes", true, false) as HBoxContainer
    _check(row != null, "Real dice selector HBox missing")
    if row == null:
        quit(1)
        return
    _check(row.get_child_count() == 7, "All 7 approved physical die buttons must fit ONE row")
    for sides in [4, 6, 8, 10, 12, 20, 100]:
        var button := dock.find_child("SelectD%d" % sides, true, false) as Button
        _check(button != null, "Missing physical D%d button" % sides)
        if button != null:
            var bounds: Rect2 = button.get_global_rect()
            _check(bounds.size.x >= 44.0 and bounds.size.y >= 44.0,
                "D%d touch target below 44 logical pixels" % sides)
            _check(dock_bounds.encloses(bounds),
                "D%d button floats outside compact dock" % sides)
    _check(hud.get_node_or_null("M3ExtraDiceControls") == null,
        "Old floating M3 D10/D100 touch controls remain")
    var toggle := dock.find_child("D100Mode", true, false) as Button
    _check(toggle != null, "Physical D100 body source switch absent")
    if toggle != null:
        scene.call("_select_die_type", 100)
        await process_frame
        await process_frame
        _check(toggle.visible, "D100-only source mode not shown after selecting D100")
        var toggle_bounds: Rect2 = toggle.get_global_rect()
        _check(dock_bounds.encloses(toggle_bounds), "D100 mode is outside the dock")
        _check(toggle_bounds.size.x >= 90.0 and toggle_bounds.size.y >= 30.0,
            "D100 mode button too small to touch")
        _check(bool(scene.get("percentile_pair_enabled")), "Default D100 must be physical two-D10")
        toggle.pressed.emit()
        _check(not bool(scene.get("percentile_pair_enabled")), "Single real D100 mode not selectable")
        toggle.pressed.emit()
        _check(bool(scene.get("percentile_pair_enabled")), "Pair of real D10 not restorable")
        scene.call("_select_die_type", 6)
        await process_frame
        _check(not toggle.visible, "D100 source controls visible on D6")
    print("M5_COMPACT_DOCK checks=%d failures=%d" % [checks, failures])
    scene.queue_free()
    quit(0 if failures == 0 else 1)
