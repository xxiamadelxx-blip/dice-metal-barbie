extends Node3D
## M3 physical D4 / D6 / D8 / D12 / D20 testbed. A numeral is shown only after Jolt settles.
## Not final UX, not yet approved as statistical fairness evidence.

const DieScript = preload("res://src/dice/d6_body.gd")
const D20Script = preload("res://src/dice/d20_body.gd")
const D8Script = preload("res://src/dice/d8_body.gd")
const D12Script = preload("res://src/dice/d12_body.gd")
const D4Script = preload("res://src/dice/d4_body.gd")
const TABLE_WIDTH := 6.8
const TABLE_LENGTH := 10.8

var active_die: RigidBody3D
var status_label: Label
var throw_button: Button
var copy_button: Button
var selected_chooser: OptionButton
var selected_die := 6
var active_sides := 6
var last_result := -1

func _ready() -> void:
    _make_world()
    _make_overlay()

func _make_world() -> void:
    var camera := Camera3D.new()
    camera.name = "FixedOverheadCamera"
    camera.position = Vector3(0.0, 18.0, 1.5)
    camera.rotation_degrees = Vector3(-90.0, 0.0, 0.0)
    camera.projection = Camera3D.PROJECTION_ORTHOGONAL
    camera.size = 16.2
    camera.current = true
    add_child(camera)

    var environment := WorldEnvironment.new()
    var env := Environment.new()
    env.background_mode = Environment.BG_COLOR
    env.background_color = Color(0.012, 0.012, 0.018)
    env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
    env.ambient_light_color = Color(0.5, 0.55, 0.66)
    env.ambient_light_energy = 0.65
    environment.environment = env
    add_child(environment)

    var light := DirectionalLight3D.new()
    light.rotation_degrees = Vector3(-55.0, 20.0, 0.0)
    light.light_energy = 1.3
    light.shadow_enabled = true
    add_child(light)

    var velvet := StandardMaterial3D.new()
    velvet.albedo_color = Color(0.028, 0.031, 0.039)
    velvet.roughness = 0.96
    _make_static_box("VelvetTable", Vector3(0, -0.24, 0), Vector3(TABLE_WIDTH, 0.4, TABLE_LENGTH), velvet)

    var rail_material := StandardMaterial3D.new()
    rail_material.albedo_color = Color(0.054, 0.059, 0.069)
    rail_material.roughness = 0.78
    _make_static_box("RailLeft", Vector3(-TABLE_WIDTH * 0.5, 0.34, 0), Vector3(0.35, 0.9, TABLE_LENGTH), rail_material)
    _make_static_box("RailRight", Vector3(TABLE_WIDTH * 0.5, 0.34, 0), Vector3(0.35, 0.9, TABLE_LENGTH), rail_material)
    _make_static_box("RailTop", Vector3(0, 0.34, -TABLE_LENGTH * 0.5), Vector3(TABLE_WIDTH, 0.9, 0.35), rail_material)
    _make_static_box("RailBottom", Vector3(0, 0.34, TABLE_LENGTH * 0.5), Vector3(TABLE_WIDTH, 0.9, 0.35), rail_material)

func _make_static_box(node_name: String, origin: Vector3, dimensions: Vector3, material: Material) -> void:
    var body := StaticBody3D.new()
    body.name = node_name
    body.position = origin
    var shape_node := CollisionShape3D.new()
    var box := BoxShape3D.new()
    box.size = dimensions
    shape_node.shape = box
    body.add_child(shape_node)
    var mesh_node := MeshInstance3D.new()
    var mesh := BoxMesh.new()
    mesh.size = dimensions
    mesh_node.mesh = mesh
    mesh_node.material_override = material
    body.add_child(mesh_node)
    add_child(body)

func _make_overlay() -> void:
    var canvas := CanvasLayer.new()
    add_child(canvas)
    var root := Control.new()
    root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    canvas.add_child(root)

    var top := Label.new()
    top.text = "D&D Dice"
    top.position = Vector2(24, 26)
    root.add_child(top)

    var panel := PanelContainer.new()
    panel.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
    panel.offset_top = -266.0
    var panel_style := StyleBoxFlat.new()
    panel_style.bg_color = Color(0.048, 0.053, 0.065, 1.0)
    panel_style.border_color = Color(0.11, 0.12, 0.15, 1.0)
    panel_style.border_width_top = 1
    panel_style.corner_radius_top_left = 14
    panel_style.corner_radius_top_right = 14
    panel_style.content_margin_left = 18
    panel_style.content_margin_right = 18
    panel_style.content_margin_top = 14
    panel_style.content_margin_bottom = 14
    panel.add_theme_stylebox_override("panel", panel_style)
    root.add_child(panel)
    var column := VBoxContainer.new()
    column.add_theme_constant_override("separation", 10)
    panel.add_child(column)
    var heading := Label.new()
    heading.text = "Кубики"
    column.add_child(heading)
    selected_chooser = OptionButton.new()
    selected_chooser.custom_minimum_size = Vector2(0, 42)
    selected_chooser.add_item("D4", 4)
    selected_chooser.add_item("D6", 6)
    selected_chooser.add_item("D8", 8)
    selected_chooser.add_item("D12", 12)
    selected_chooser.add_item("D20", 20)
    ## Keep the visual selection aligned with the default D6 throw button.
    selected_chooser.select(1)
    selected_chooser.item_selected.connect(_on_type_selected)
    column.add_child(selected_chooser)
    throw_button = Button.new()
    throw_button.text = "Бросить D6"
    throw_button.custom_minimum_size = Vector2(0, 54)
    throw_button.pressed.connect(_throw_selected_die)
    column.add_child(throw_button)
    status_label = Label.new()
    status_label.text = "Выбери кубик и нажми «Бросить»"
    column.add_child(status_label)
    copy_button = Button.new()
    copy_button.custom_minimum_size = Vector2(0, 40)
    copy_button.text = "Скопировать результат"
    copy_button.disabled = true
    copy_button.pressed.connect(_copy_result)
    column.add_child(copy_button)

func _copy_result() -> void:
    if last_result != -1:
        DisplayServer.clipboard_set(str(last_result))
        status_label.text = "Скопировано: D%d = %d" % [active_sides, last_result]

func _on_type_selected(index: int) -> void:
    selected_die = selected_chooser.get_item_id(index)
    throw_button.text = "Бросить D%d" % selected_die

func _throw_selected_die() -> void:
    match selected_die:
        4:
            _throw_physical_d4()
        8:
            _throw_physical_d8()
        12:
            _throw_physical_d12()
        20:
            _throw_physical_d20()
        _:
            _throw_physical_d6()

func _throw_physical_d6() -> void:
    _begin_throw(DieScript.new(), 6)

func _throw_physical_d4() -> void:
    _begin_throw(D4Script.new(), 4)

func _throw_physical_d20() -> void:
    _begin_throw(D20Script.new(), 20)

func _throw_physical_d8() -> void:
    _begin_throw(D8Script.new(), 8)

func _throw_physical_d12() -> void:
    _begin_throw(D12Script.new(), 12)

func _begin_throw(die: RigidBody3D, sides: int) -> void:
    if not throw_button or throw_button.disabled:
        die.queue_free()
        return
    active_sides = sides
    last_result = -1
    copy_button.disabled = true
    throw_button.disabled = true
    selected_chooser.disabled = true
    if is_instance_valid(active_die):
        remove_child(active_die)
        active_die.queue_free()
    die.name = "PhysicalD%d" % sides
    add_child(die)
    active_die = die
    die.connect("roll_completed", Callable(self, "_on_die_completed"))
    die.connect("roll_failed", Callable(self, "_on_die_failed"))
    die.call("throw_from_top")
    status_label.text = "D%d · кубик летит…" % sides

func _on_die_completed(value: int) -> void:
    last_result = value
    if active_sides == 20 and value == 20:
        status_label.text = "D20 · 20 · критический успех"
    elif active_sides == 20 and value == 1:
        status_label.text = "D20 · 1 · критический провал"
    else:
        status_label.text = "D%d · результат: %d" % [active_sides, value]
    throw_button.disabled = false
    selected_chooser.disabled = false
    copy_button.disabled = false

func _on_die_failed(message: String) -> void:
    status_label.text = "Бросок не засчитан: %s" % message
    throw_button.disabled = false
    selected_chooser.disabled = false
