extends RigidBody3D
## Physically simulated, visibly numbered D8. No post-roll orientation correction.
signal roll_completed(value: int)
signal roll_failed(reason: String)

const Octa = preload("res://src/core/octahedron.gd")
const DiceRng = preload("res://src/core/dice_rng.gd")
const Sculpt = preload("res://src/visual/sculpted_d20.gd")
const MAX_ROLL_SECONDS := 9.0

var rolling := false
var result := -1
var failure := ""
var elapsed := 0.0
var edge_recovery_count := 0

func _ready() -> void:
    name = "PhysicalD8"
    mass = 0.04
    continuous_cd = true
    can_sleep = true
    linear_damp = 0.16
    angular_damp = 0.19

    var phys := PhysicsMaterial.new()
    phys.friction = 0.73
    phys.bounce = 0.17
    physics_material_override = phys

    var collider := CollisionShape3D.new()
    collider.name = "OctahedronCollision"
    var shape := ConvexPolygonShape3D.new()
    shape.points = Octa.vertices()
    collider.shape = shape
    add_child(collider)
    _create_visual()

func _create_visual() -> void:
    var positions := Octa.vertices()
    var face_indices: Array = []
    for facet in range(8):
        face_indices.append(Octa.face_indices(facet))
    var body := MeshInstance3D.new()
    body.name = "ObsidianD8"
    body.mesh = Sculpt.face_planes(Octa.vertices(), face_indices)
    var obsidian := StandardMaterial3D.new()
    obsidian.albedo_color = Color(0.023, 0.031, 0.049)
    obsidian.metallic = 0.24
    obsidian.roughness = 0.20
    body.material_override = obsidian
    add_child(body)
    var bevel := MeshInstance3D.new()
    bevel.name = "ActualSculptedBevels"
    bevel.mesh = Sculpt.chamfers(Octa.vertices(), face_indices)
    bevel.material_override = Sculpt.bevel_material()
    add_child(bevel)
    var inlay := MeshInstance3D.new()
    inlay.name = "FaceInsetBronzeHairlines"
    inlay.mesh = Sculpt.inlaid_tracery(Octa.vertices(), face_indices)
    inlay.material_override = Sculpt.gold_groove_material()
    add_child(inlay)

    var values := Octa.numbers()
    for face_id in range(8):
        var normal: Vector3 = Octa.face_normal(face_id)
        var number: int = values[face_id]
        var label := Label3D.new()
        label.name = "Face_%d" % number
        label.text = str(number)
        label.font_size = 50
        label.pixel_size = 0.0056
        label.outline_size = 6
        label.modulate = Color(0.95, 0.88, 0.74)
        label.outline_modulate = Color(0.06, 0.07, 0.10)
        label.double_sided = false
        label.no_depth_test = false
        label.shaded = true
        label.position = Octa.face_center(face_id) + normal * 0.0025
        var up := Vector3.BACK if absf(normal.y) > 0.7 else Vector3.UP
        label.basis = Basis.looking_at(normal, up, true)
        add_child(label)

func throw_from_top() -> void:
    rolling = true
    result = -1
    failure = ""
    elapsed = 0.0
    edge_recovery_count = 0
    sleeping = false
    var chosen := DiceRng.pick(24) - 1
    if chosen < 0:
        _abort("Не удалось получить случайное значение")
        return
    var random_axis := Vector3(randf_range(0.2, 1.0), randf_range(0.2, 1.0), randf_range(0.2, 1.0)).normalized()
    basis = Basis(Quaternion(random_axis, randf_range(-1.8, 1.8))) * Octa.rotations()[chosen]
    position = Vector3(randf_range(-1.0, 1.0), 2.4, -3.3)
    apply_central_impulse(Vector3(randf_range(-0.023, 0.023), 0.025, randf_range(0.105, 0.165)))
    apply_torque_impulse(Vector3(randf_range(-0.008, 0.008), randf_range(-0.008, 0.008), randf_range(-0.008, 0.008)))

func _physics_process(delta: float) -> void:
    if not rolling:
        return
    elapsed += delta
    if elapsed > MAX_ROLL_SECONDS:
        _abort("D8 не остановился за 9 секунд")
        return
    if position.y < -0.15 or absf(position.x) > 3.1 or absf(position.z) > 5.2:
        _abort("D8 покинул игровую поверхность")
        return
    if not sleeping or elapsed < 0.3:
        return
    var pose := global_transform.basis.orthonormalized()
    var face := Octa.top_face(pose)
    var best := 0.0
    for i in range(8):
        var alignment: float = (pose * Octa.face_normal(i)).dot(Vector3.UP)
        best = maxf(best, alignment)
    if face < 0 or best < 0.89:
        ## Rare solver rest on an unstable edge: give the body a small, label-independent
        ## world-space physical impulse. NEVER snap/rotate it to a chosen number.
        if edge_recovery_count < 3 and elapsed < MAX_ROLL_SECONDS - 1.5:
            edge_recovery_count += 1
            sleeping = false
            apply_central_impulse(Vector3(0.006, 0.008, 0.004))
            apply_torque_impulse(Vector3(0.005, 0.003, -0.004))
            return
        _abort("D8 не смог устойчиво остановиться на грани")
        return
    rolling = false
    result = Octa.numbers()[face]
    roll_completed.emit(result)

func _abort(message: String) -> void:
    rolling = false
    failure = message
    roll_failed.emit(message)

func numeral_node(face: int) -> Label3D:
    return get_node_or_null("Face_%d" % face) as Label3D
