extends Node3D
## M3 physical D4 / D6 / D8 / D12 / D20 testbed. A numeral is shown only after Jolt settles.
## Not final UX, not yet approved as statistical fairness evidence.

const Premium = preload("res://src/visual/premium_finish.gd")
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
var die_buttons: Dictionary = {}
var idle_display: Node3D

func _ready() -> void:
    _make_world()
    _make_idle_showcase()
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
    env.background_color = Color(0.006, 0.007, 0.011)
    env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
    env.ambient_light_color = Color(0.42, 0.45, 0.54)
    env.ambient_light_energy = 0.8
    # Studio environment light is reflected in the obsidian but NOT displayed
    # as a sky/background. Dark table and clean void stay user-approved.
    var studio_sky := Sky.new()
    var studio := ProceduralSkyMaterial.new()
    studio.sky_top_color = Color(0.20, 0.25, 0.35)
    studio.sky_horizon_color = Color(0.48, 0.42, 0.34)
    studio.ground_bottom_color = Color(0.05, 0.06, 0.08)
    studio.ground_horizon_color = Color(0.12, 0.14, 0.19)
    studio_sky.sky_material = studio
    env.sky = studio_sky
    env.reflected_light_source = Environment.REFLECTION_SOURCE_SKY
    environment.environment = env
    add_child(environment)

    var light := DirectionalLight3D.new()
    light.rotation_degrees = Vector3(-63.0, 24.0, 0.0)
    light.light_energy = 1.6
    light.shadow_enabled = true
    add_child(light)

    var velvet := Premium.velvet_material()
    _make_static_box("VelvetTable", Vector3(0, -0.24, 0), Vector3(TABLE_WIDTH, 0.4, TABLE_LENGTH), velvet)

    var rail_material := Premium.blackened_metal()
    _make_static_box("RailLeft", Vector3(-TABLE_WIDTH * 0.5, 0.34, 0), Vector3(0.35, 0.9, TABLE_LENGTH), rail_material)
    _make_static_box("RailRight", Vector3(TABLE_WIDTH * 0.5, 0.34, 0), Vector3(0.35, 0.9, TABLE_LENGTH), rail_material)
    _make_static_box("RailTop", Vector3(0, 0.34, -TABLE_LENGTH * 0.5), Vector3(TABLE_WIDTH, 0.9, 0.35), rail_material)
    _make_static_box("RailBottom", Vector3(0, 0.34, TABLE_LENGTH * 0.5), Vector3(TABLE_WIDTH, 0.9, 0.35), rail_material)
    # Inlaid warm metal along the *inner* edges of the solid table rails.
    var rim := Premium.gold_material()
    _make_visual_trim("WarmRimLeft", Vector3(-3.23, 0.805, 0), Vector3(0.025, 0.025, 10.25), rim)
    _make_visual_trim("WarmRimRight", Vector3(3.23, 0.805, 0), Vector3(0.025, 0.025, 10.25), rim)
    _make_visual_trim("WarmRimTop", Vector3(0, 0.805, -5.24), Vector3(6.5, 0.025, 0.025), rim)
    _make_visual_trim("WarmRimBottom", Vector3(0, 0.805, 5.24), Vector3(6.5, 0.025, 0.025), rim)
    _make_accent_light(Vector3(-2.7, 6.0, -3.4), Color(1.0, 0.74, 0.46), 480.0, 0.85)
    _make_accent_light(Vector3(3.0, 6.5, 3.0), Color(0.54, 0.71, 1.0), 440.0, 0.42)

func _make_visual_trim(node_name: String, origin: Vector3, dimensions: Vector3, material: Material) -> void:
    var line := MeshInstance3D.new()
    line.name = node_name
    line.position = origin
    var shape := BoxMesh.new()
    shape.size = dimensions
    line.mesh = shape
    line.material_override = material
    add_child(line)

func _make_accent_light(origin: Vector3, tint: Color, range_value: float, strength: float) -> void:
    var lamp := OmniLight3D.new()
    lamp.position = origin
    lamp.light_color = tint
    lamp.omni_range = range_value / 100.0
    lamp.light_energy = strength
    lamp.shadow_enabled = false
    add_child(lamp)


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

func _chip_style(selected: bool) -> StyleBoxFlat:
    var box_style := StyleBoxFlat.new()
    box_style.bg_color = Color(0.12, 0.105, 0.085, 0.98) if selected else Color(0.035, 0.043, 0.056, 0.96)
    box_style.border_color = Color(0.88, 0.65, 0.32) if selected else Color(0.15, 0.17, 0.20)
    box_style.set_border_width_all(1)
    box_style.set_corner_radius_all(13)
    box_style.content_margin_left = 5
    box_style.content_margin_right = 5
    box_style.content_margin_top = 10
    box_style.content_margin_bottom = 9
    return box_style

func _make_idle_showcase() -> void:
    # Non-rolling collectible display. They are actual numbered 3D models,
    # visibly arranged across the velvet like the approved third concept.
    # All preview collision layers are disabled and the showcase is removed
    # before the first real throw; it never invents a numeric roll result.
    idle_display = Node3D.new()
    idle_display.name = "IdleDiceDisplay"
    add_child(idle_display)
    var layout := [
        {"script": D20Script, "sides": 20, "location": Vector3(-1.5, 0.77, -2.6), "angle": Vector3(14, -25, 18)},
        {"script": D12Script, "sides": 12, "location": Vector3(1.45, 0.73, -2.1), "angle": Vector3(-18, 40, 20)},
        {"script": DieScript, "sides": 6, "location": Vector3(-1.35, 0.62, 0.6), "angle": Vector3(9, 35, -12)},
        {"script": D4Script, "sides": 4, "location": Vector3(1.55, 0.58, 1.55), "angle": Vector3(8, -20, 22)}
    ]
    for item in layout:
        var scene_script: GDScript = item["script"]
        var preview: RigidBody3D = scene_script.new()
        idle_display.add_child(preview)
        preview.name = "PreviewD%d" % item["sides"]
        preview.freeze = true
        preview.collision_layer = 0
        preview.collision_mask = 0
        preview.position = item["location"]
        preview.rotation_degrees = item["angle"]
        Premium.decorate_die(preview, item["sides"])

func _make_overlay() -> void:
    var canvas := CanvasLayer.new()
    canvas.name = "GameHUD"
    add_child(canvas)
    var root := Control.new()
    root.name = "OverlayRoot"
    root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    canvas.add_child(root)

    var brand := Label.new()
    brand.name = "AppTitle"
    brand.text = "D&D  /  DICE"
    brand.position = Vector2(26, 28)
    brand.add_theme_font_size_override("font_size", 19)
    brand.add_theme_color_override("font_color", Color(0.94, 0.89, 0.77))
    root.add_child(brand)

    # This is a genuinely minimalist single-screen control dock, not a Godot
    # prototype form. Unsupported dice are not presented as dead controls.
    var panel := PanelContainer.new()
    panel.name = "ControlDock"
    panel.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
    panel.offset_top = -236.0
    var surface := StyleBoxFlat.new()
    surface.bg_color = Color(0.023, 0.031, 0.043, 1.0)
    surface.border_color = Color(0.19, 0.22, 0.27)
    surface.border_width_top = 1
    surface.corner_radius_top_left = 22
    surface.corner_radius_top_right = 22
    surface.content_margin_left = 20
    surface.content_margin_right = 20
    surface.content_margin_top = 15
    surface.content_margin_bottom = 13
    panel.add_theme_stylebox_override("panel", surface)
    root.add_child(panel)

    var column := VBoxContainer.new()
    column.add_theme_constant_override("separation", 12)
    panel.add_child(column)
    var heading := Label.new()
    heading.text = "ВЫБЕРИ КУБИК"
    heading.add_theme_font_size_override("font_size", 12)
    heading.add_theme_color_override("font_color", Color(0.55, 0.61, 0.72))
    column.add_child(heading)

    # A synchronized invisible option state is retained for the existing
    # accessibility/physics regressions. Visible controls are tappable chips.
    selected_chooser = OptionButton.new()
    selected_chooser.add_item("D4", 4)
    selected_chooser.add_item("D6", 6)
    selected_chooser.add_item("D8", 8)
    selected_chooser.add_item("D12", 12)
    selected_chooser.add_item("D20", 20)
    selected_chooser.select(1)
    selected_chooser.visible = false
    selected_chooser.item_selected.connect(_on_type_selected)
    column.add_child(selected_chooser)

    var chips := HBoxContainer.new()
    chips.name = "DiceTypes"
    chips.add_theme_constant_override("separation", 8)
    column.add_child(chips)
    var types := [4, 6, 8, 12, 20]
    var icons := ["△", "□", "◇", "⬟", "⬡"]
    for i in range(types.size()):
        var sides: int = types[i]
        var chip := Button.new()
        chip.name = "SelectD%d" % sides
        chip.text = "%s\nD%d" % [icons[i], sides]
        chip.custom_minimum_size = Vector2(0, 67)
        chip.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        chip.add_theme_font_size_override("font_size", 16)
        chip.add_theme_color_override("font_color", Color(0.92, 0.91, 0.87))
        chip.add_theme_color_override("font_hover_color", Color.WHITE)
        chip.add_theme_stylebox_override("normal", _chip_style(sides == selected_die))
        chip.add_theme_stylebox_override("hover", _chip_style(true))
        chip.add_theme_stylebox_override("pressed", _chip_style(true))
        chip.tooltip_text = "Выбрать D%d" % sides
        chip.pressed.connect(_select_die_type.bind(sides))
        die_buttons[sides] = chip
        chips.add_child(chip)

    var lower := HBoxContainer.new()
    lower.name = "ThrowAndResult"
    lower.custom_minimum_size = Vector2(0, 91)
    lower.add_theme_constant_override("separation", 12)
    column.add_child(lower)

    var result_stack := VBoxContainer.new()
    result_stack.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    result_stack.alignment = BoxContainer.ALIGNMENT_CENTER
    result_stack.add_theme_constant_override("separation", 3)
    lower.add_child(result_stack)
    status_label = Label.new()
    status_label.name = "RollReadout"
    status_label.text = "ГОТОВО К БРОСКУ"
    status_label.add_theme_font_size_override("font_size", 23)
    status_label.add_theme_color_override("font_color", Color(0.95, 0.91, 0.82))
    result_stack.add_child(status_label)
    var hint := Label.new()
    hint.text = "Физический бросок · результат по грани"
    hint.add_theme_font_size_override("font_size", 11)
    hint.add_theme_color_override("font_color", Color(0.49, 0.55, 0.63))
    result_stack.add_child(hint)

    copy_button = Button.new()
    copy_button.name = "CopyRoll"
    copy_button.text = "⧉  КОПИРОВАТЬ"
    copy_button.visible = false
    copy_button.disabled = true
    copy_button.add_theme_font_size_override("font_size", 12)
    copy_button.add_theme_color_override("font_color", Color(0.78, 0.83, 0.89))
    copy_button.add_theme_stylebox_override("normal", _chip_style(false))
    copy_button.pressed.connect(_copy_result)
    result_stack.add_child(copy_button)

    var action_stack := VBoxContainer.new()
    action_stack.alignment = BoxContainer.ALIGNMENT_CENTER
    action_stack.add_theme_constant_override("separation", 2)
    lower.add_child(action_stack)
    throw_button = Button.new()
    throw_button.name = "PhysicalRollButton"
    throw_button.text = "⬡"
    throw_button.tooltip_text = "Бросить D6"
    throw_button.custom_minimum_size = Vector2(83, 83)
    throw_button.add_theme_font_size_override("font_size", 37)
    throw_button.add_theme_color_override("font_color", Color.WHITE)
    var action_style := StyleBoxFlat.new()
    action_style.bg_color = Color(0.075, 0.35, 0.75)
    action_style.border_color = Color(0.30, 0.67, 0.99)
    action_style.set_border_width_all(2)
    action_style.set_corner_radius_all(43)
    throw_button.add_theme_stylebox_override("normal", action_style)
    throw_button.add_theme_stylebox_override("hover", action_style)
    throw_button.add_theme_stylebox_override("pressed", action_style)
    throw_button.pressed.connect(_throw_selected_die)
    action_stack.add_child(throw_button)

func _select_die_type(sides: int) -> void:
    for index in range(selected_chooser.item_count):
        if selected_chooser.get_item_id(index) == sides:
            selected_chooser.select(index)
            _on_type_selected(index)
            break

func _copy_result() -> void:
    if last_result != -1:
        DisplayServer.clipboard_set(str(last_result))
        status_label.text = "Скопировано: D%d = %d" % [active_sides, last_result]

func _on_type_selected(index: int) -> void:
    selected_die = selected_chooser.get_item_id(index)
    throw_button.tooltip_text = "Бросить D%d" % selected_die
    for die_sides in die_buttons:
        var chip: Button = die_buttons[die_sides]
        chip.add_theme_stylebox_override("normal", _chip_style(die_sides == selected_die))

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
    if is_instance_valid(idle_display):
        idle_display.queue_free()
        idle_display = null
    copy_button.disabled = true
    throw_button.disabled = true
    selected_chooser.disabled = true
    if is_instance_valid(active_die):
        remove_child(active_die)
        active_die.queue_free()
    die.name = "PhysicalD%d" % sides
    add_child(die)
    Premium.decorate_die(die, sides)
    active_die = die
    die.connect("roll_completed", Callable(self, "_on_die_completed"))
    die.connect("roll_failed", Callable(self, "_on_die_failed"))
    die.call("throw_from_top")
    status_label.text = "D%d  ·  БРОСОК…" % sides
    copy_button.visible = false

func _on_die_completed(value: int) -> void:
    last_result = value
    if active_sides == 20 and value == 20:
        status_label.text = "✦  20  ·  КРИТИЧЕСКИЙ УСПЕХ"
    elif active_sides == 20 and value == 1:
        status_label.text = "1  ·  КРИТИЧЕСКИЙ ПРОВАЛ"
    else:
        status_label.text = "D%d   /   %d" % [active_sides, value]
    throw_button.disabled = false
    selected_chooser.disabled = false
    copy_button.disabled = false
    copy_button.visible = true

func _on_die_failed(message: String) -> void:
    status_label.text = "Бросок не засчитан: %s" % message
    copy_button.visible = false
    throw_button.disabled = false
    selected_chooser.disabled = false
