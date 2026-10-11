extends RigidBody3D
## M3 physically colliding numbered D20 (regular icosahedron).
## Value comes ONLY from the settled upper face. No snap, no forced result.

signal roll_completed(value: int)
signal roll_failed(reason: String)

const Ico = preload("res://src/core/icosahedron.gd")
const Sculpt = preload("res://src/visual/sculpted_d20.gd")
const DiceRng = preload("res://src/core/dice_rng.gd")
const MAX_ROLL_SECONDS := 9.0
# Actual Jolt recovery when sleeping on an ambiguous EDGE, never face
# snapping or value substitution. Preserve 9s overall physics time budget.
const MAX_EDGE_RECOVERY_ATTEMPTS := 6

var rolling := false
var result := -1
var failure := ""
var elapsed := 0.0
var edge_recovery_count := 0

func _ready() -> void:
    name = "PhysicalD20"
    mass = 0.045
    continuous_cd = true
    can_sleep = true
    linear_damp = 0.16
    angular_damp = 0.19

    var physics_material := PhysicsMaterial.new()
    physics_material.friction = 0.72
    physics_material.bounce = 0.16
    physics_material_override = physics_material

    var collision := CollisionShape3D.new()
    collision.name = "IcosahedronCollision"
    var shape := ConvexPolygonShape3D.new()
    shape.points = Ico.vertices()
    collision.shape = shape
    add_child(collision)

    _create_geometry_and_numerals()

func _create_geometry_and_numerals() -> void:
    var vertices := Ico.vertices()
    var labels := Ico.numbers()

    var mesh_node := MeshInstance3D.new()
    mesh_node.name = "ObsidianD20"
    mesh_node.mesh = Sculpt.face_planes(vertices, Ico.FACES)
    var obsidian := StandardMaterial3D.new()
    obsidian.albedo_color = Color(0.026, 0.033, 0.052)
    obsidian.metallic = 0.26
    obsidian.roughness = 0.18
    mesh_node.material_override = obsidian
    add_child(mesh_node)

    var shoulders := MeshInstance3D.new()
    shoulders.name = "ActualSculptedBevels"
    shoulders.mesh = Sculpt.chamfers(vertices, Ico.FACES)
    shoulders.material_override = Sculpt.bevel_material()
    add_child(shoulders)
    var traces := MeshInstance3D.new()
    traces.name = "FaceInsetBronzeHairlines"
    traces.mesh = Sculpt.inlaid_tracery(vertices, Ico.FACES)
    traces.material_override = Sculpt.gold_groove_material()
    add_child(traces)

    for face_id in range(20):
        var normal: Vector3 = Ico.face_normal(face_id)
        var number := labels[face_id]
        var label := Label3D.new()
        label.name = "Face_%d" % number
        label.text = str(number)
        label.font_size = 50
        label.pixel_size = 0.0056
        label.outline_size = 5
        label.modulate = Color(0.95, 0.89, 0.74)
        label.outline_modulate = Color(0.05, 0.06, 0.095)
        label.double_sided = false
        label.no_depth_test = false
        label.shaded = true
        label.position = Ico.face_center(face_id) + normal * 0.0025
        var face_up := Vector3.BACK if absf(normal.y) > 0.7 else Vector3.UP
        label.basis = Basis.looking_at(normal, face_up, true)
        add_child(label)

func throw_from_top() -> void:
    result = -1
    failure = ""
    elapsed = 0.0
    edge_recovery_count = 0
    sleeping = false
    rolling = true

    var all_rotations := Ico.proper_rotations()
    var selected_index := DiceRng.pick(60) - 1
    if selected_index < 0:
        _abort("Не удалось получить случайное значение")
        return

    var random_axis := Vector3(randf_range(0.2, 1.0), randf_range(0.2, 1.0), randf_range(0.2, 1.0)).normalized()
    var base_pose := Basis(Quaternion(random_axis, randf_range(-1.8, 1.8)))
    basis = base_pose * all_rotations[selected_index]
    position = Vector3(randf_range(-1.0, 1.0), 2.45, -3.2)
    apply_central_impulse(Vector3(randf_range(-0.028, 0.028), 0.027, randf_range(0.10, 0.17)))
    apply_torque_impulse(Vector3(randf_range(-0.009, 0.009), randf_range(-0.009, 0.009), randf_range(-0.009, 0.009)))

func _physics_process(delta: float) -> void:
    if not rolling:
        return
    elapsed += delta
    if elapsed > MAX_ROLL_SECONDS:
        _abort("D20 не остановился за 9 секунд")
        return
    if position.y < -0.15 or absf(position.x) > 3.1 or absf(position.z) > 5.2:
        _abort("D20 покинул игровую поверхность")
        return
    if not sleeping or elapsed < 0.3:
        return

    var pose := global_transform.basis.orthonormalized()
    var face := Ico.top_face(pose, 0.02)
    var best_alignment := 0.0
    for i in range(20):
        var dot_up: float = (pose * Ico.face_normal(i)).dot(Vector3.UP)
        best_alignment = maxf(best_alignment, dot_up)
    if face < 0 or best_alignment < 0.88:
        ## Real world-frame impulse only; never twist to a selected number.
        if edge_recovery_count < MAX_EDGE_RECOVERY_ATTEMPTS and elapsed < MAX_ROLL_SECONDS - 0.75:
            # A symmetric alternating *real Jolt* nudge dislodges a
            # multi-body D20 leaning between faces. Increasing impulse by
            # bounded attempts is independent of the printed face label.
            # Never rotate/freeze the body or generate a synthetic result.
            edge_recovery_count += 1
            var phase := float(edge_recovery_count)
            var direction := -1.0 if edge_recovery_count % 2 == 0 else 1.0
            sleeping = false
            apply_central_impulse(Vector3(
                direction * (0.005 + 0.0015 * phase),
                0.007 + 0.001 * phase,
                -direction * (0.004 + 0.001 * phase)))
            apply_torque_impulse(Vector3(
                direction * (0.004 + 0.0014 * phase),
                0.003,
                -direction * (0.004 + 0.0014 * phase)))
            if OS.is_debug_build():
                print("DICE_D20_REAL_EDGE_RECOVERY attempt=%d alignment=%.4f elapsed=%.2f" % [
                    edge_recovery_count,best_alignment,elapsed])
            return
        _abort("D20 не смог устойчиво остановиться на грани после %d реальных импульсов" % edge_recovery_count)
        return
    rolling = false
    result = Ico.numbers()[face]
    roll_completed.emit(result)

func _abort(message: String) -> void:
    rolling = false
    failure = message
    roll_failed.emit(message)

func numeral_node(face: int) -> Label3D:
    return get_node_or_null("Face_%d" % face) as Label3D
