extends Node3D
## M2 foundation: interactive rigid-body scene, NOT a completed dice roller.

const TABLE_WIDTH := 6.8
const TABLE_LENGTH := 10.8

var active_die: RigidBody3D
var status_label: Label

func _ready() -> void:
    _make_world()
    _make_overlay()

func _make_world() -> void:
    var camera := Camera3D.new()
    camera.name = "FixedOverheadCamera"
    camera.position = Vector3(0.0, 18.0, 0.0)
    camera.rotation_degrees = Vector3(-90.0, 0.0, 0.0)
    camera.projection = Camera3D.PROJECTION_ORTHOGONAL
    camera.size = 13.8
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
    velvet.albedo_color = Color(0.014, 0.014, 0.019)
    velvet.roughness = 0.96
    _make_static_box("VelvetTable", Vector3(0, -0.24, 0), Vector3(TABLE_WIDTH, 0.4, TABLE_LENGTH), velvet)

    var rail_material := StandardMaterial3D.new()
    rail_material.albedo_color = Color(0.028, 0.029, 0.033)
    rail_material.roughness = 0.78
    _make_static_box("RailLeft", Vector3(-TABLE_WIDTH * 0.5, 0.34, 0), Vector3(0.35, 0.9, TABLE_LENGTH), rail_material)
    _make_static_box("RailRight", Vector3(TABLE_WIDTH * 0.5, 0.34, 0), Vector3(0.35, 0.9, TABLE_LENGTH), rail_material)
    _make_static_box("RailTop", Vector3(0, 0.34, -TABLE_LENGTH * 0.5), Vector3(TABLE_WIDTH, 0.9, 0.35), rail_material)
    _make_static_box("RailBottom", Vector3(0, 0.34, TABLE_LENGTH * 0.5), Vector3(TABLE_WIDTH, 0.9, 0.35), rail_material)

func _make_static_box(node_name: String, origin: Vector3, dimensions: Vector3, material: Material) -> void:
    var body := StaticBody3D.new()
    body.name = node_name
    body.position = origin
    var shape := CollisionShape3D.new()
    var box := BoxShape3D.new()
    box.size = dimensions
    shape.shape = box
    body.add_child(shape)
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
    top.text = "D&D 3D Dice   ·   M2"
    top.position = Vector2(20, 25)
    root.add_child(top)

    var panel := PanelContainer.new()
    panel.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
    panel.offset_top = -190.0
    root.add_child(panel)
    var column := VBoxContainer.new()
    column.add_theme_constant_override("separation", 14)
    panel.add_child(column)
    var heading := Label.new()
    heading.text = "Физический стенд · D6"
    column.add_child(heading)
    var button := Button.new()
    button.text = "Бросить D6"
    button.custom_minimum_size = Vector2(0, 64)
    button.pressed.connect(_throw_physical_d6)
    column.add_child(button)
    status_label = Label.new()
    status_label.text = "Результат и цифры на гранях: этап M3."
    column.add_child(status_label)

func _throw_physical_d6() -> void:
    if is_instance_valid(active_die):
        active_die.queue_free()
    var die := RigidBody3D.new()
    die.name = "PhysicalD6"
    die.mass = 0.04
    die.continuous_cd = true
    die.position = Vector3(randf_range(-1.3, 1.3), 2.4, -3.4)

    var physics_material := PhysicsMaterial.new()
    physics_material.friction = 0.65
    physics_material.bounce = 0.22
    die.physics_material_override = physics_material

    var shape_node := CollisionShape3D.new()
    var shape := BoxShape3D.new()
    shape.size = Vector3(0.72, 0.72, 0.72)
    shape_node.shape = shape
    die.add_child(shape_node)

    var mesh_node := MeshInstance3D.new()
    var cube := BoxMesh.new()
    cube.size = shape.size
    mesh_node.mesh = cube
    var obsidian := StandardMaterial3D.new()
    obsidian.albedo_color = Color(0.032, 0.039, 0.054)
    obsidian.metallic = 0.18
    obsidian.roughness = 0.24
    mesh_node.material_override = obsidian
    die.add_child(mesh_node)

    add_child(die)
    active_die = die
    die.apply_central_impulse(Vector3(randf_range(-0.02, 0.02), 0.024, randf_range(0.12, 0.18)))
    die.apply_torque_impulse(Vector3(randf_range(-0.020, 0.020), randf_range(-0.020, 0.020), randf_range(-0.020, 0.020)))
    status_label.text = "Физический бросок. Значение пока не вычисляется."

