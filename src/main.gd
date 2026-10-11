extends Node3D
## M3 physical D4 / D6 / D8 / D12 / D20 testbed. A numeral is shown only after Jolt settles.
## Not final UX, not yet approved as statistical fairness evidence.

const Premium = preload("res://src/visual/premium_finish.gd")
const CriticalAura = preload("res://src/visual/critical_aura.gd")
const DieScript = preload("res://src/dice/d6_body.gd")
const D20Script = preload("res://src/dice/d20_body.gd")
const D8Script = preload("res://src/dice/d8_body.gd")
const D12Script = preload("res://src/dice/d12_body.gd")
const D4Script = preload("res://src/dice/d4_body.gd")
const TrapezohedronDie = preload("res://src/dice/trapezohedron_body.gd")
const DiceRules = preload("res://src/core/dice_rules.gd")
const RollFormula = preload("res://src/core/roll_formula.gd")
const RollStore = preload("res://src/core/roll_persistence.gd")
const PhysicalPool = preload("res://src/core/physical_roll_pool.gd")
const AdvancedDrawer = preload("res://src/ui/m4_advanced_roll_drawer.gd")
const TABLE_WIDTH := 6.8
const TABLE_LENGTH := 10.8
# Launch display only. Never scale physically simulated dice or Jolt colliders.
const IDLE_HERO_SCALE := 1.38

var active_die: RigidBody3D
var active_percentile: Node3D
var percentile_tens := -1
var percentile_ones := -1
var d100_mode_button: Button
var percentile_pair_enabled := true
var status_label: Label
var throw_button: Button
var copy_button: Button
var selected_chooser: OptionButton
var selected_die := 6
var active_sides := 6
var last_result := -1
var die_buttons: Dictionary = {}
var idle_display: Node3D
var advanced_panel: PanelContainer
var physical_pool: Node3D
var roll_store: RefCounted
var advanced_open_button: Button
var last_advanced_formula := ""

func _ready() -> void:
    _make_world()
    _make_idle_showcase()
    _make_overlay()
    _setup_m4_local_and_drawer()

func _setup_m4_local_and_drawer() -> void:
    # Functional M4 bottom-sheet substitute; M5 will do final skin/navigation.
    roll_store = RollStore.new()
    var loaded: Dictionary = roll_store.call("load_state")
    var overlay := get_node("GameHUD/OverlayRoot") as Control
    advanced_open_button = Button.new()
    advanced_open_button.name = "OpenAdvancedRules"
    advanced_open_button.text = "≡"
    advanced_open_button.tooltip_text = "Составные броски, история и пресеты"
    advanced_open_button.position = Vector2(25, 73)
    advanced_open_button.custom_minimum_size = Vector2(51, 48)
    advanced_open_button.pressed.connect(_toggle_advanced_rules)
    overlay.add_child(advanced_open_button)
    advanced_panel = AdvancedDrawer.new()
    overlay.add_child(advanced_panel)
    advanced_panel.connect("physical_roll_requested",Callable(self,"_request_advanced_throw"))
    advanced_panel.connect("preset_save_requested",Callable(self,"_save_m4_preset"))
    advanced_panel.connect("preset_delete_requested",Callable(self,"_delete_m4_preset"))
    advanced_panel.connect("history_clear_requested",Callable(self,"_confirm_m4_history_clear"))
    advanced_panel.call("refresh_local_state",roll_store.call("snapshot"))
    if not bool(loaded.get("ok",false)):
        advanced_panel.call("show_message","Локальный файл требует восстановления; запись заблокирована")

func _toggle_advanced_rules() -> void:
    if advanced_panel == null:
        return
    advanced_panel.visible = not advanced_panel.visible

func _record_m4_result(result: Dictionary) -> void:
    if roll_store == null or not bool(result.get("ok",false)):
        return
    var saved: Dictionary = roll_store.call("append_physical_result",result)
    if advanced_panel != null:
        advanced_panel.call("refresh_local_state",roll_store.call("snapshot"))
        if not bool(saved.get("ok",false)):
            advanced_panel.call("show_message",str(saved.get("error","Не удалось сохранить историю")))

func _clear_pool_for_basic_throw() -> void:
    if is_instance_valid(physical_pool):
        if bool(physical_pool.get("busy")):
            return
        if physical_pool.get_parent() == self:
            remove_child(physical_pool)
        physical_pool.queue_free()
        physical_pool = null

func _request_advanced_throw(expression: String, mode: String, d100_mode: String) -> void:
    if throw_button.disabled:
        return
    if is_instance_valid(physical_pool) and bool(physical_pool.get("busy")):
        return
    _clear_pool_for_basic_throw()
    if is_instance_valid(active_die):
        if active_die.get_parent() == self:
            remove_child(active_die)
        active_die.queue_free()
        active_die = null
    if is_instance_valid(active_percentile):
        if active_percentile.get_parent() == self:
            remove_child(active_percentile)
        active_percentile.queue_free()
        active_percentile = null
    if is_instance_valid(idle_display):
        if idle_display.get_parent() == self:
            remove_child(idle_display)
        idle_display.queue_free()
        idle_display = null
    physical_pool = PhysicalPool.new()
    physical_pool.name = "M4PhysicalDicePool"
    add_child(physical_pool)
    physical_pool.connect("pool_completed",Callable(self,"_m4_physical_completed"))
    physical_pool.connect("pool_failed",Callable(self,"_m4_physical_failed"))
    var accepted: bool = physical_pool.call("begin",expression,mode,d100_mode)
    if not accepted:
        return
    last_result = -1
    last_advanced_formula = expression
    status_label.text = "СОСТАВНОЙ БРОСОК…"
    throw_button.disabled = true
    selected_chooser.disabled = true
    copy_button.visible = false
    copy_button.disabled = true
    advanced_panel.call("set_roll_locked",true)
    advanced_panel.call("show_message","Jolt: выполняются реальные физические броски")

func _m4_physical_completed(result: Dictionary) -> void:
    if not bool(result.get("ok",false)):
        _m4_physical_failed("Итоговый расчёт недействителен")
        return
    last_result = int(result.get("total",0))
    active_sides = 0
    last_advanced_formula = str(result.get("formula",""))
    status_label.text = "%s = %d" % [last_advanced_formula,last_result]
    copy_button.visible = true
    copy_button.disabled = false
    throw_button.disabled = false
    selected_chooser.disabled = false
    advanced_panel.call("set_roll_locked",false)
    advanced_panel.call("show_message","Итог по настоящим физическим граням: %d" % last_result)
    _record_m4_result(result)
    if OS.is_debug_build():
        print("DICE_M4_PHYSICAL_COMPLETED %s=%d" % [last_advanced_formula,last_result])

func _m4_physical_failed(message: String) -> void:
    status_label.text = "Составной бросок не засчитан"
    throw_button.disabled = false
    selected_chooser.disabled = false
    copy_button.visible = false
    copy_button.disabled = true
    if advanced_panel != null:
        advanced_panel.call("set_roll_locked",false)
        advanced_panel.call("show_message",message)
    if OS.is_debug_build():
        print("DICE_M4_PHYSICAL_FAILED "+message)

func _save_m4_preset(title: String, formula: String, mode: String,
        d100_mode: String) -> void:
    var saved: Dictionary = roll_store.call("upsert_preset",title,formula,mode,d100_mode)
    advanced_panel.call("show_message","Пресет сохранён" if bool(saved.get("ok",false))
        else str(saved.get("error","Не удалось сохранить")))
    advanced_panel.call("refresh_local_state",roll_store.call("snapshot"))

func _delete_m4_preset(title: String) -> void:
    var ask := ConfirmationDialog.new()
    ask.title = "Удалить пресет?"
    ask.dialog_text = "Удалить «%s» из памяти устройства?" % title
    add_child(ask)
    ask.confirmed.connect(func():
        var deleted: Dictionary = roll_store.call("delete_preset",title,true)
        advanced_panel.call("show_message","Пресет удалён" if bool(deleted.get("ok",false))
            else str(deleted.get("error","Не удалось удалить")))
        advanced_panel.call("refresh_local_state",roll_store.call("snapshot"))
        ask.queue_free())
    ask.canceled.connect(func(): ask.queue_free())
    ask.popup_centered()

func _confirm_m4_history_clear() -> void:
    var ask := ConfirmationDialog.new()
    ask.title = "Очистить историю?"
    ask.dialog_text = "Все сохранённые броски будут удалены с устройства."
    add_child(ask)
    ask.confirmed.connect(func():
        var cleared: Dictionary = roll_store.call("clear_history",true)
        advanced_panel.call("show_message","История очищена" if bool(cleared.get("ok",false))
            else str(cleared.get("error","Не удалось очистить")))
        advanced_panel.call("refresh_local_state",roll_store.call("snapshot"))
        ask.queue_free())
    ask.canceled.connect(func(): ask.queue_free())
    ask.popup_centered()

func _make_world() -> void:
    var camera := Camera3D.new()
    camera.name = "FixedOverheadCamera"
    camera.position = Vector3(0.0, 18.0, 1.5)
    camera.rotation_degrees = Vector3(-90.0, 0.0, 0.0)
    camera.projection = Camera3D.PROJECTION_ORTHOGONAL
    # Fill more of a 720x1280 phone screen while preserving every table rail
    # in the 90-degree overhead orthographic frame.
    camera.size = 14.2
    camera.current = true
    add_child(camera)

    var environment := WorldEnvironment.new()
    var env := Environment.new()
    env.background_mode = Environment.BG_COLOR
    env.background_color = Color(0.006, 0.007, 0.011)
    env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
    env.ambient_light_color = Color(0.51, 0.57, 0.67)
    env.ambient_light_energy = 1.05
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
    light.light_energy = 1.28
    light.shadow_enabled = true
    add_child(light)

    # Opposing, broad-spectrum studio bounce lifts faceted shadows without
    # changing the approved 90-degree camera or adding white rim tubes.
    # Intentional secondary light, not a second shadow caster: mobile friendly.
    var fill := DirectionalLight3D.new()
    fill.name = "SoftStudioBounce"
    fill.rotation_degrees = Vector3(-46.0, -133.0, 0.0)
    fill.light_color = Color(0.72, 0.83, 1.0)
    fill.light_energy = 0.76
    fill.shadow_enabled = false
    add_child(fill)

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
        {"script": D4Script, "sides": 4, "location": Vector3(1.55, 0.38, 1.55), "angle": Vector3(8, -20, 22)}
    ]
    for item in layout:
        var scene_script: GDScript = item["script"]
        var preview: RigidBody3D = scene_script.new()
        idle_display.add_child(preview)
        preview.name = "PreviewD%d" % item["sides"]
        preview.freeze = true
        preview.collision_layer = 0
        preview.collision_mask = 0
        var source_location: Vector3 = item["location"]
        # Launch composition was too sparse on a 720x1280 handset. Scale the
        # four NON-ROLLING collectible previews only, and lift their centers
        # with the same ratio to keep the visual bases near velvet.
        preview.position = Vector3(source_location.x, source_location.y * IDLE_HERO_SCALE, source_location.z)
        preview.rotation_degrees = item["angle"]
        preview.scale = Vector3.ONE * IDLE_HERO_SCALE
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
    selected_chooser.add_item("D10", 10)
    selected_chooser.add_item("D100", 100)
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

    # Temporary M3 mechanical controls outside the original 5-button dock,
    # preserving existing Android touch coordinates and the approved stage.
    # Full visual composition and typography are deferred to M5.
    var extended := HBoxContainer.new()
    extended.name = "M3ExtraDiceControls"
    extended.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
    extended.offset_top = -323
    extended.offset_bottom = -247
    extended.offset_left = 245
    extended.offset_right = -20
    extended.add_theme_constant_override("separation", 8)
    root.add_child(extended)
    for extra_sides in [10, 100]:
        var extra := Button.new()
        extra.name = "SelectD%d" % extra_sides
        extra.text = "D%d" % extra_sides
        extra.custom_minimum_size = Vector2(76, 55)
        extra.add_theme_font_size_override("font_size", 16)
        extra.add_theme_stylebox_override("normal", _chip_style(false))
        extra.add_theme_stylebox_override("pressed", _chip_style(true))
        extra.pressed.connect(_select_die_type.bind(extra_sides))
        die_buttons[extra_sides] = extra
        extended.add_child(extra)
    d100_mode_button = Button.new()
    d100_mode_button.name = "D100Mode"
    d100_mode_button.text = "2 × D10"
    d100_mode_button.tooltip_text = "Переключить один D100 / два D10"
    d100_mode_button.visible = false
    d100_mode_button.custom_minimum_size = Vector2(105, 55)
    d100_mode_button.pressed.connect(_toggle_d100_mode)
    extended.add_child(d100_mode_button)

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

func _toggle_d100_mode() -> void:
    percentile_pair_enabled = not percentile_pair_enabled
    d100_mode_button.text = "2 × D10" if percentile_pair_enabled else "1 × D100"

func _select_die_type(sides: int) -> void:
    for index in range(selected_chooser.item_count):
        if selected_chooser.get_item_id(index) == sides:
            selected_chooser.select(index)
            _on_type_selected(index)
            break

func _copy_result() -> void:
    if last_result != -1:
        DisplayServer.clipboard_set(str(last_result))
        if active_sides == 0:
            status_label.text = "Скопировано: %s = %d" % [last_advanced_formula,last_result]
        else:
            status_label.text = "Скопировано: D%d = %d" % [active_sides,last_result]

func _on_type_selected(index: int) -> void:
    selected_die = selected_chooser.get_item_id(index)
    throw_button.tooltip_text = "Бросить D%d" % selected_die
    if d100_mode_button != null:
        d100_mode_button.visible = selected_die == 100
    for die_sides in die_buttons:
        var chip: Button = die_buttons[die_sides]
        chip.add_theme_stylebox_override("normal", _chip_style(die_sides == selected_die))

func _throw_selected_die() -> void:
    if is_instance_valid(physical_pool) and bool(physical_pool.get("busy")):
        return
    match selected_die:
        4:
            _throw_physical_d4()
        8:
            _throw_physical_d8()
        12:
            _throw_physical_d12()
        20:
            _throw_physical_d20()
        10:
            _throw_physical_d10()
        100:
            if percentile_pair_enabled:
                _throw_percentile_d100()
            else:
                _throw_physical_d100()
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

func _throw_physical_d10() -> void:
    var die: RigidBody3D = TrapezohedronDie.new()
    die.set("sides", 10)
    _begin_throw(die, 10)

func _throw_physical_d100() -> void:
    var die: RigidBody3D = TrapezohedronDie.new()
    die.set("sides", 100)
    _begin_throw(die, 100)

func _throw_percentile_d100() -> void:
    if not throw_button or throw_button.disabled:
        return
    _clear_pool_for_basic_throw()
    active_sides = 100
    last_result = -1
    percentile_tens = -1
    percentile_ones = -1
    if is_instance_valid(idle_display):
        idle_display.queue_free()
        idle_display = null
    if is_instance_valid(active_die):
        # queue_free() deletes at end-of-frame, leaving an old collider live
        # for the next physics step. Detach from SceneTree immediately.
        if active_die.get_parent() == self:
            remove_child(active_die)
        active_die.queue_free()
        active_die = null
    if is_instance_valid(active_percentile):
        # Repeated two-D10 throws previously left the queued parent with
        # the same node name. get_node() then found the OLD settled pair.
        # The old two colliders must also be removed from Jolt immediately.
        if active_percentile.get_parent() == self:
            remove_child(active_percentile)
        active_percentile.queue_free()
        active_percentile = null
    active_percentile = Node3D.new()
    active_percentile.name = "PhysicalD100Percentile"
    add_child(active_percentile)
    copy_button.visible = false
    copy_button.disabled = true
    throw_button.disabled = true
    selected_chooser.disabled = true
    for is_tens in [true, false]:
        var die: RigidBody3D = TrapezohedronDie.new()
        die.set("sides", 10)
        die.name = "TensD10" if is_tens else "OnesD10"
        active_percentile.add_child(die)
        die.connect("roll_completed", Callable(self, "_on_percentile_finished").bind(is_tens))
        die.connect("roll_failed", Callable(self, "_on_die_failed"))
        die.call("throw_from_top", -1 if is_tens else 1)
    status_label.text = "D100  ·  ДВА БРОСКА…"
    if OS.is_debug_build():
        print("DICE_QA_STARTED D100_PAIR")

func _on_percentile_finished(value: int, is_tens: bool) -> void:
    if is_tens:
        percentile_tens = value
    else:
        percentile_ones = value
    if percentile_tens == -1 or percentile_ones == -1:
        return
    # Printed 10 corresponds to zero on each percentile digit; only the
    # physically visible two faces determine the combined result.
    last_result = DiceRules.percentile((percentile_tens % 10) * 10, percentile_ones % 10)
    if last_result < 1:
        _on_die_failed("Ошибка процентного броска")
        return
    status_label.text = "D100   /   %d" % last_result
    copy_button.visible = true
    copy_button.disabled = false
    throw_button.disabled = false
    selected_chooser.disabled = false
    var percentile_spec: Dictionary = RollFormula.parse("1d100")
    var observed: Dictionary = RollFormula.evaluate(percentile_spec,
        [[{"tens":percentile_tens,"ones":percentile_ones}]])
    _record_m4_result(observed)
    if OS.is_debug_build():
        print("DICE_QA_COMPLETED D100_PAIR=%d" % last_result)

func _begin_throw(die: RigidBody3D, sides: int) -> void:
    if not throw_button or throw_button.disabled:
        die.queue_free()
        return
    _clear_pool_for_basic_throw()
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
    if is_instance_valid(active_percentile):
        # Switching from two percentiles back to one physical die must
        # leave no orphan physics bodies in the running scene.
        if active_percentile.get_parent() == self:
            remove_child(active_percentile)
        active_percentile.queue_free()
        active_percentile = null
    die.name = "PhysicalD%d" % sides
    add_child(die)
    if sides != 10 and sides != 100:
        Premium.decorate_die(die, sides)
    active_die = die
    die.connect("roll_completed", Callable(self, "_on_die_completed"))
    die.connect("roll_failed", Callable(self, "_on_die_failed"))
    die.call("throw_from_top")
    # Debug-only Android AVD handshake. Reflects REAL physical signals,
    # never replaces or sets the numeric outcome.
    if OS.is_debug_build():
        print("DICE_QA_STARTED D%d" % sides)
    status_label.text = "D%d  ·  БРОСОК…" % sides
    copy_button.visible = false

func _on_die_completed(value: int) -> void:
    last_result = value
    if OS.is_debug_build():
        print("DICE_QA_COMPLETED D%d=%d" % [active_sides, value])
    # Only the physically settled face signal can trigger a critical aura.
    # This effect attaches in 3D space, never to the result HUD.
    if is_instance_valid(active_die):
        CriticalAura.spawn(active_die, active_sides, value)
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
    var single_spec: Dictionary = RollFormula.parse("1d%d" % active_sides)
    var recorded: Dictionary = RollFormula.evaluate(single_spec,[[value]])
    _record_m4_result(recorded)

func _on_die_failed(message: String) -> void:
    if OS.is_debug_build():
        var key := "100_PAIR" if active_sides == 100 and is_instance_valid(active_percentile) else str(active_sides)
        print("DICE_QA_FAILED D%s=%s" % [key, message])
    status_label.text = "Бросок не засчитан: %s" % message
    copy_button.visible = false
    throw_button.disabled = false
    selected_chooser.disabled = false
