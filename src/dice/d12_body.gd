extends RigidBody3D
## Real numbered D12. 20-vertex convex Jolt body with twelve pentagons.
## Numerals are visual-only. Final result is physically upward face after sleep.
signal roll_completed(value: int)
signal roll_failed(reason: String)

const Dodeca = preload("res://src/core/dodecahedron.gd")
const DiceRng = preload("res://src/core/dice_rng.gd")
const MAX_ROLL_SECONDS := 9.0

var rolling := false
var result := -1
var failure := ""
var elapsed := 0.0
var edge_recovery_count := 0

func _ready() -> void:
    name = "PhysicalD12"
    mass = 0.045
    continuous_cd = true
    can_sleep = true
    linear_damp = 0.18
    angular_damp = 0.20
    var material := PhysicsMaterial.new()
    material.friction = 0.74
    material.bounce = 0.16
    physics_material_override = material

    var collider := CollisionShape3D.new()
    collider.name = "DodecahedronCollision"
    var shape := ConvexPolygonShape3D.new()
    shape.points = Dodeca.vertices()
    collider.shape = shape
    add_child(collider)
    _create_visual()

func _create_visual() -> void:
    var points := Dodeca.vertices()
    var mesh := SurfaceTool.new()
    mesh.begin(Mesh.PRIMITIVE_TRIANGLES)
    for face_id in range(12):
        var indices := Dodeca.face_indices(face_id)
        var normal := Dodeca.face_normal(face_id)
        for triangle in range(1, indices.size() - 1):
            for vertex_id in [indices[0], indices[triangle], indices[triangle + 1]]:
                mesh.set_normal(normal)
                mesh.add_vertex(points[vertex_id])
    var body := MeshInstance3D.new()
    body.name = "ObsidianD12"
    body.mesh = mesh.commit()
    var stone := StandardMaterial3D.new()
    stone.albedo_color = Color(0.023, 0.031, 0.051)
    stone.metallic = 0.24
    stone.roughness = 0.20
    body.material_override = stone
    add_child(body)

    var numbered := Dodeca.numbers()
    for i in range(12):
        var normal: Vector3 = Dodeca.face_normal(i)
        var value: int = numbered[i]
        var glyph := Label3D.new()
        glyph.name = "Face_%d" % value
        glyph.text = str(value)
        glyph.font_size = 51
        glyph.pixel_size = 0.005
        glyph.outline_size = 6
        glyph.modulate = Color(0.94, 0.87, 0.74)
        glyph.outline_modulate = Color(0.05, 0.07, 0.10)
        glyph.double_sided = false
        glyph.no_depth_test = false
        glyph.shaded = true
        glyph.position = Dodeca.face_center(i) + normal * 0.0025
        var face_up := Vector3.BACK if absf(normal.y) > 0.7 else Vector3.UP
        glyph.basis = Basis.looking_at(normal, face_up, true)
        add_child(glyph)

func throw_from_top() -> void:
    rolling = true
    failure = ""
    result = -1
    elapsed = 0.0
    edge_recovery_count = 0
    sleeping = false
    var selection := DiceRng.pick(60) - 1
    if selection < 0:
        _abort("Не удалось получить случайное значение")
        return
    var axis := Vector3(randf_range(0.2, 1.0), randf_range(0.2, 1.0), randf_range(0.2, 1.0)).normalized()
    basis = Basis(Quaternion(axis, randf_range(-1.75, 1.75))) * Dodeca.rotations()[selection]
    position = Vector3(randf_range(-1.0, 1.0), 2.35, -3.2)
    apply_central_impulse(Vector3(randf_range(-0.027, 0.027), 0.026, randf_range(0.11, 0.18)))
    apply_torque_impulse(Vector3(randf_range(-0.008, 0.008), randf_range(-0.008, 0.008), randf_range(-0.008, 0.008)))

func _physics_process(delta: float) -> void:
    if not rolling:
        return
    elapsed += delta
    if elapsed > MAX_ROLL_SECONDS:
        _abort("D12 не остановился за 9 секунд")
        return
    if position.y < -0.15 or absf(position.x) > 3.1 or absf(position.z) > 5.2:
        _abort("D12 покинул игровую поверхность")
        return
    if not sleeping or elapsed < 0.3:
        return
    var pose := global_transform.basis.orthonormalized()
    var face := Dodeca.top_face(pose)
    var best := 0.0
    for i in range(12):
        var alignment: float = (pose * Dodeca.face_normal(i)).dot(Vector3.UP)
        best = maxf(best, alignment)
    if face < 0 or best < 0.91:
        ## Stabilize only through real dynamics. No after-roll face snap.
        if edge_recovery_count < 3 and elapsed < MAX_ROLL_SECONDS - 1.5:
            edge_recovery_count += 1
            sleeping = false
            apply_central_impulse(Vector3(0.005, 0.008, 0.004))
            apply_torque_impulse(Vector3(0.004, 0.003, -0.004))
            return
        _abort("D12 не смог устойчиво остановиться на грани")
        return
    rolling = false
    result = Dodeca.numbers()[face]
    roll_completed.emit(result)

func _abort(message: String) -> void:
    rolling = false
    failure = message
    roll_failed.emit(message)

func numeral_node(face: int) -> Label3D:
    return get_node_or_null("Face_%d" % face) as Label3D
