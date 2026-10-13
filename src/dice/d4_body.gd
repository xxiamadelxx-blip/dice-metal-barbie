extends RigidBody3D
## Real Jolt tetrahedral D4: physically rests on one triangular face.
## Value is the top APEX, visibly repeated on its three neighbouring faces.
signal roll_completed(value: int)
signal roll_failed(reason: String)

const Tetra = preload("res://src/core/tetrahedron.gd")
const DiceRng = preload("res://src/core/dice_rng.gd")
const Sculpt = preload("res://src/visual/sculpted_d20.gd")
const MAX_ROLL_SECONDS := 9.0

var rolling := false
var result := -1
var failure := ""
var elapsed := 0.0
var edge_recovery_count := 0

func _ready() -> void:
    name = "PhysicalD4"
    mass = 0.038
    continuous_cd = true
    can_sleep = true
    linear_damp = 0.17
    angular_damp = 0.19
    var phys := PhysicsMaterial.new()
    phys.friction = 0.73
    phys.bounce = 0.17
    physics_material_override = phys

    var collider := CollisionShape3D.new()
    collider.name = "TetrahedronCollision"
    var shape := ConvexPolygonShape3D.new()
    shape.points = Tetra.vertices()
    collider.shape = shape
    add_child(collider)
    _create_visual()

func _create_visual() -> void:
    var points := Tetra.vertices()
    var face_indices: Array = []
    for facet in range(4):
        face_indices.append(Tetra.face_indices(facet))
    var body := MeshInstance3D.new()
    body.name = "ObsidianD4"
    body.mesh = Sculpt.face_planes(Tetra.vertices(), face_indices)
    var obsidian := StandardMaterial3D.new()
    obsidian.albedo_color = Color(0.024, 0.032, 0.049)
    obsidian.metallic = 0.25
    obsidian.roughness = 0.19
    body.material_override = obsidian
    add_child(body)
    var bevel := MeshInstance3D.new()
    bevel.name = "ActualSculptedBevels"
    bevel.mesh = Sculpt.chamfers(Tetra.vertices(), face_indices)
    bevel.material_override = Sculpt.bevel_material()
    add_child(bevel)
    var inlay := MeshInstance3D.new()
    inlay.name = "FaceInsetBronzeHairlines"
    inlay.mesh = Sculpt.inlaid_tracery(Tetra.vertices(), face_indices)
    inlay.material_override = Sculpt.gold_groove_material()
    add_child(inlay)

    ## Three glyphs of identical value appear around each apex.
    ## This makes the result legible from a fixed overhead camera.
    for apex in range(4):
        for opposite in range(4):
            if apex == opposite:
                continue
            var outward := Tetra.face_normal(opposite)
            var label := Label3D.new()
            label.name = "Apex_%d_OnFace_%d" % [apex + 1, opposite]
            label.text = str(apex + 1)
            label.font_size = 48
            label.pixel_size = 0.0040
            label.outline_size = 5
            label.modulate = Color(0.94, 0.87, 0.73)
            label.outline_modulate = Color(0.04, 0.05, 0.08)
            label.double_sided = false
            label.no_depth_test = false
            label.shaded = true
            label.position = Tetra.printed_position(apex, opposite)
            var up := Vector3.BACK if absf(outward.y) > 0.7 else Vector3.UP
            label.basis = Basis.looking_at(outward, up, true)
            add_child(label)

func throw_from_top() -> void:
    result = -1
    failure = ""
    elapsed = 0.0
    edge_recovery_count = 0
    rolling = true
    sleeping = false
    var selected := DiceRng.pick(12) - 1
    if selected < 0:
        _abort("Не удалось получить случайное значение")
        return
    var axis := Vector3(randf_range(0.2, 1.0), randf_range(0.2, 1.0), randf_range(0.2, 1.0)).normalized()
    basis = Basis(Quaternion(axis, randf_range(-1.7, 1.7))) * Tetra.rotations()[selected]
    position = Vector3(randf_range(-1.0, 1.0), 2.35, -3.15)
    apply_central_impulse(Vector3(randf_range(-0.024, 0.024), 0.025, randf_range(0.11, 0.17)))
    apply_torque_impulse(Vector3(randf_range(-0.008, 0.008), randf_range(-0.008, 0.008), randf_range(-0.008, 0.008)))

func _physics_process(delta: float) -> void:
    if not rolling:
        return
    elapsed += delta
    if elapsed > MAX_ROLL_SECONDS:
        _abort("D4 не смог завершить бросок за 9 секунд")
        return
    if position.y < -0.15 or absf(position.x) > 3.1 or absf(position.z) > 5.2:
        _abort("D4 покинул поверхность стола")
        return
    if not sleeping or elapsed < 0.3:
        return
    var pose := global_transform.basis.orthonormalized()
    var apex := Tetra.top_vertex(pose)
    var strongest := 0.0
    for v in Tetra.vertices():
        var aligned: float = (pose * v.normalized()).dot(Vector3.UP)
        strongest = maxf(strongest, aligned)
    if apex < 0 or strongest < 0.88:
        if edge_recovery_count < 3 and elapsed < MAX_ROLL_SECONDS - 1.5:
            edge_recovery_count += 1
            sleeping = false
            apply_central_impulse(Vector3(0.005, 0.008, 0.004))
            apply_torque_impulse(Vector3(0.004, 0.003, -0.004))
            return
        _abort("D4 остановился на ребре, результат не определён")
        return
    rolling = false
    result = apex + 1
    roll_completed.emit(result)

func _abort(reason: String) -> void:
    rolling = false
    failure = reason
    roll_failed.emit(reason)

func glyph(value: int, face: int) -> Label3D:
    return get_node_or_null("Apex_%d_OnFace_%d" % [value, face]) as Label3D
