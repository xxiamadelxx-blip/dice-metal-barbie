extends SceneTree
## UI geometry regression from actual cloud rendered frame defects (Issue #20).

var failed := 0
var checked := 0

func _require(ok: bool, detail: String) -> void:
    checked += 1
    if not ok:
        failed += 1
        push_error(detail)

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    var packed: PackedScene = load("res://src/main.tscn")
    _require(packed != null, "Main scene unavailable")
    if packed == null:
        quit(1)
        return
    var app: Node3D = packed.instantiate()
    root.size = Vector2i(720, 1280)
    root.add_child(app)
    await process_frame

    var camera: Camera3D = app.get_node("FixedOverheadCamera")
    var panel: PanelContainer = app.get_node("CanvasLayer/Control/PanelContainer")
    var label: Label = app.get_node("CanvasLayer/Control/Label")
    _require(camera.rotation_degrees.distance_to(Vector3(-90, 0, 0)) < 0.001, "Camera must remain strictly top-down")
    _require(camera.projection == Camera3D.PROJECTION_ORTHOGONAL, "Camera must stay orthographic")
    _require(label.text == "D&D Dice", "Do not display development diagnostics as UI heading")

    var s := panel.get_theme_stylebox("panel") as StyleBoxFlat
    _require(s != null, "Bottom dock requires a fully opaque background")
    if s != null:
        _require(s.bg_color.a >= 0.999, "Bottom dock must be opaque")

    var table_bottom := camera.unproject_position(Vector3(0.0, 0.0, 5.4))
    var dock_top: float = panel.get_global_rect().position.y
    _require(table_bottom.y + 20.0 < dock_top, "World table must not intersect controls: table y=%f dock y=%f" % [table_bottom.y, dock_top])
    _require(app.selected_chooser.get_selected_id() == app.selected_die, "Chooser must agree with active throw")
    _require(app.throw_button.text == "Бросить D6", "Initial throw must match initial choice")
    print("M3 visual layout: %d checks, %d failures" % [checked, failed])
    quit(0 if failed == 0 else 1)
