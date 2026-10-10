extends RigidBody3D
## Real D10 or D100 Jolt rigid body, with an exact 10/100-face convex hull.
## The settled physical top face determines the value; no virtual RNG result.
signal roll_completed(value: int)
signal roll_failed(reason: String)

const ShapeMath = preload("res://src/core/trapezohedron.gd")
const DiceRng = preload("res://src/core/dice_rng.gd")
const Sculpt = preload("res://src/visual/sculpted_d20.gd")
var sides: int = 10
var rolling := false
var result := -1
var failure := ""
var elapsed := 0.0
var edge_recovery_count := 0

func _ready() -> void:
    assert(sides == 10 or sides == 100)
    mass = 0.050 if sides == 10 else 0.065
    continuous_cd = true
    can_sleep = true
    linear_damp = 0.20
    angular_damp = 0.24
    var friction := PhysicsMaterial.new()
    friction.friction = 0.74
    friction.bounce = 0.13
    physics_material_override = friction
    var collision := CollisionShape3D.new()
    collision.name = "TrapezohedronCollision"
    var convex := ConvexPolygonShape3D.new()
    convex.points = ShapeMath.vertices(sides)
    collision.shape = convex
    add_child(collision)
    var indices: Array = []
    for face in range(sides):
        indices.append(ShapeMath.face_indices(sides, face))
    var shell := MeshInstance3D.new()
    shell.name = "ObsidianD%d" % sides
    shell.mesh = Sculpt.face_planes(ShapeMath.vertices(sides), indices)
    var obsidian := StandardMaterial3D.new()
    obsidian.albedo_color = Color(0.035, 0.045, 0.064)
    obsidian.metallic = 0.23
    obsidian.roughness = 0.27
    shell.material_override = obsidian
    add_child(shell)
    var font_scale := 0.0040 if sides == 10 else 0.00052
    var values := ShapeMath.numbers(sides)
    for face in range(sides):
        var value: int = values[face]
        var label := Label3D.new()
        label.name = "Face_%d" % value
        label.text = str(value % 10) if sides == 10 else str(value)
        label.font_size = 54
        label.pixel_size = font_scale
        label.modulate = Color(0.89, 0.72, 0.47)
        label.outline_modulate = Color(0.025, 0.025, 0.035)
        label.outline_size = 5
        label.shaded = true
        label.no_depth_test = false
        label.double_sided = false
        var normal := ShapeMath.face_normal(sides, face)
        label.position = ShapeMath.face_center(sides, face) + normal * 0.0012
        var up := Vector3.BACK if absf(normal.y) > 0.8 else Vector3.UP
        label.basis = Basis.looking_at(normal, up, true)
        add_child(label)

func throw_from_top(lane: int = 0) -> void:
    rolling = true
    result = -1
    failure = ""
    elapsed = 0.0
    edge_recovery_count = 0
    sleeping = false
    var selection := DiceRng.pick(sides) - 1
    if selection < 0:
        _abort("Нет случайной энтропии")
        return
    var ring: int = sides / 2
    var flip := selection >= ring
    var spin := TAU * float(selection % ring) / float(ring)
    var turn := Basis(Vector3.UP, spin)
    if flip:
        # The antiprism's upper/lower rings are offset by pi/n.
        # Rotate 180° around a horizontal axis at pi/(2n), not global X:
        # only this is an actual proper shape symmetry for BOTH sizes.
        var symmetry_axis := Vector3(cos(PI / float(sides)), 0.0,
            sin(PI / float(sides))).normalized()
        turn = Basis(symmetry_axis, PI) * turn
    var axis := Vector3(randf_range(0.3, 1.0), randf_range(0.3, 1.0), randf_range(0.3, 1.0)).normalized()
    basis = Basis(Quaternion(axis, randf_range(-1.8, 1.8))) * turn
    position = Vector3(float(lane) * 1.0 + randf_range(-0.16, 0.16), 2.65, -3.25)
    apply_central_impulse(Vector3(randf_range(-0.024, 0.024), 0.027, randf_range(0.12, 0.17)))
    apply_torque_impulse(Vector3(randf_range(-0.008, 0.008), randf_range(-0.008, 0.008), randf_range(-0.008, 0.008)))

func _physics_process(delta: float) -> void:
    if not rolling:
        return
    elapsed += delta
    var timeout := 18.0 if sides == 100 else 10.0
    if elapsed > timeout:
        _abort("D%d не остановился вовремя" % sides)
        return
    if position.y < -0.15 or absf(position.x) > 3.1 or absf(position.z) > 5.2:
        _abort("D%d покинул игровой стол" % sides)
        return
    if not sleeping or elapsed < 0.3:
        return
    var pose := global_transform.basis.orthonormalized()
    var face := ShapeMath.top_face(sides, pose)
    var alignment := 0.0
    for f in range(sides):
        alignment = maxf(alignment, (pose * ShapeMath.face_normal(sides, f)).dot(Vector3.UP))
    if face < 0 or alignment < (0.95 if sides == 100 else 0.89):
        if edge_recovery_count < 4 and elapsed < timeout - 2.0:
            edge_recovery_count += 1
            sleeping = false
            apply_central_impulse(Vector3(0.005, 0.009, 0.004))
            apply_torque_impulse(Vector3(0.004, 0.003, -0.005))
            return
        _abort("D%d остался на неоднозначном ребре" % sides)
        return
    rolling = false
    result = ShapeMath.numbers(sides)[face]
    roll_completed.emit(result)

func _abort(message: String) -> void:
    rolling = false
    failure = message
    roll_failed.emit(message)

func numeral_node(value: int) -> Label3D:
    return get_node_or_null("Face_%d" % value) as Label3D
