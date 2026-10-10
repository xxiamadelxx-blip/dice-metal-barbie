extends RigidBody3D
## M3 numbered D6: labels are fixed to the rigid body's own six faces.
## The physically uppermost label is the only source of the visible result.
## Proper cubic symmetry is chosen via Crypto BEFORE physics starts.

signal roll_completed(value: int)
signal roll_failed(reason: String)

const CubeSymmetry = preload("res://src/core/cube_symmetry.gd")
const SIDE := 0.72
const MAX_ROLL_SECONDS := 9.0

var elapsed := 0.0
var rolling := false
var result := -1
var failure := ""
var entropy_rotation: Basis = Basis.IDENTITY

func _ready() -> void:
    name = "PhysicalD6"
    mass = 0.04
    continuous_cd = true
    can_sleep = true
    linear_damp = 0.12
    angular_damp = 0.16

    var physics_material := PhysicsMaterial.new()
    physics_material.friction = 0.73
    physics_material.bounce = 0.19
    physics_material_override = physics_material

    var collider := CollisionShape3D.new()
    collider.name = "SymmetricCubeCollision"
    var shape := BoxShape3D.new()
    shape.size = Vector3.ONE * SIDE
    collider.shape = shape
    add_child(collider)

    var stone := StandardMaterial3D.new()
    stone.albedo_color = Color(0.022, 0.03, 0.045)
    stone.metallic = 0.24
    stone.roughness = 0.18
    var mesh_node := MeshInstance3D.new()
    mesh_node.name = "Obsidian"
    var cube := BoxMesh.new()
    cube.size = Vector3.ONE * SIDE
    mesh_node.mesh = cube
    mesh_node.material_override = stone
    add_child(mesh_node)
    _create_face_numerals()

func _create_face_numerals() -> void:
    ## Number nodes are visual-only; no asymmetric collision or mass is added.
    for i in range(CubeSymmetry.D6_FACE_NORMALS.size()):
        var normal: Vector3 = CubeSymmetry.D6_FACE_NORMALS[i]
        var face_number: int = CubeSymmetry.D6_FACE_VALUES[i]
        var label := Label3D.new()
        label.name = "Face_%d" % face_number
        label.text = str(face_number)
        label.font_size = 64
        label.pixel_size = 0.0065
        label.modulate = Color(0.93, 0.87, 0.7)
        label.outline_modulate = Color(0.07, 0.085, 0.12)
        label.outline_size = 8
        label.double_sided = false
        label.no_depth_test = false
        label.billboard = BaseMaterial3D.BILLBOARD_DISABLED
        label.shaded = true
        label.position = normal * (SIDE * 0.5 + 0.0025)
        var face_up := Vector3.BACK if absf(normal.y) > 0.5 else Vector3.UP
        label.basis = Basis.looking_at(normal, face_up, true)
        add_child(label)

func throw_from_top() -> void:
    ## The physical hull is unchanged by this orientation; number meshes rotate with it.
    ## World-space impulse is independent of the sampled cube symmetry.
    result = -1
    failure = ""
    elapsed = 0.0
    rolling = true
    sleeping = false
    entropy_rotation = CubeSymmetry.pick_rotation()
    var random_axis := Vector3(randf_range(0.15, 1.0), randf_range(0.15, 1.0), randf_range(0.15, 1.0)).normalized()
    var pose := Basis(Quaternion(random_axis, randf_range(-1.7, 1.7)))
    basis = pose * entropy_rotation
    position = Vector3(randf_range(-1.15, 1.15), 2.35, -3.5)
    apply_central_impulse(Vector3(randf_range(-0.025, 0.025), 0.028, randf_range(0.11, 0.17)))
    apply_torque_impulse(Vector3(randf_range(-0.008, 0.008), randf_range(-0.008, 0.008), randf_range(-0.008, 0.008)))

func _physics_process(delta: float) -> void:
    if not rolling:
        return
    elapsed += delta
    if elapsed > MAX_ROLL_SECONDS:
        _abort("Не удалось завершить бросок за 9 секунд")
        return
    if position.y < -0.15 or absf(position.x) > 3.1 or absf(position.z) > 5.2:
        _abort("Кубик покинул игровую поверхность")
        return
    if not sleeping or elapsed < 0.3:
        return
    var top := CubeSymmetry.top_value(global_transform.basis.orthonormalized(), 0.02)
    var best_alignment := 0.0
    for normal in CubeSymmetry.D6_FACE_NORMALS:
        var alignment := (global_transform.basis * normal).normalized().dot(Vector3.UP)
        best_alignment = maxf(best_alignment, alignment)
    if top < 1 or best_alignment < 0.92:
        _abort("Кубик остановился на ребре; результат не определён")
        return
    rolling = false
    result = top
    roll_completed.emit(result)

func _abort(message: String) -> void:
    rolling = false
    failure = message
    roll_failed.emit(message)

func numeral_node(face: int) -> Label3D:
    return get_node_or_null("Face_%d" % face) as Label3D
