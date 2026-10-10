extends SceneTree
## Exact regular D8 geometry, 24 shape symmetries, opposite-face numbering.
const Octa = preload("res://src/core/octahedron.gd")
var checks := 0
var failures := 0

func _initialize() -> void:
    call_deferred("_run")

func _expect(ok: bool, message: String) -> void:
    checks += 1
    if not ok:
        failures += 1
        push_error(message)

func _run() -> void:
    var vertices := Octa.vertices()
    _expect(vertices.size() == 6, "D8 needs six vertices")
    var labels := Octa.numbers()
    _expect(labels.size() == 8, "D8 needs eight numbered faces")
    var seen := {}
    for i in range(8):
        var n: Vector3 = Octa.face_normal(i)
        _expect(n.dot(Octa.face_center(i)) > 0.0, "Face winding must point out")
        _expect(n.dot(Octa.face_normal(i ^ 7)) < -0.999, "Antipodal normal required")
        _expect(labels[i] + labels[i ^ 7] == 9, "Opposite values sum to nine")
        seen[labels[i]] = true
    _expect(seen.size() == 8, "Eight unique labels required")
    for value in range(1, 9):
        _expect(seen.has(value), "Missing D8 label %d" % value)
    var rotations := Octa.rotations()
    _expect(rotations.size() == 24, "Regular octahedron must have 24 proper rotations")
    var unique := {}
    for transform in rotations:
        unique[str(transform)] = true
        _expect(absf(transform.determinant() - 1.0) < 0.0001, "Only proper rotations")
        for v in vertices:
            var transformed: Vector3 = transform * v
            var matched := false
            for u in vertices:
                if transformed.distance_to(u) < 0.0001:
                    matched = true
                    break
            _expect(matched, "Rotation must preserve collision geometry")
    _expect(unique.size() == 24, "All rotations unique")

    var generic_poses := [
        Basis(Quaternion(Vector3(0.33, 0.49, 0.81).normalized(), 0.87)),
        Basis(Quaternion(Vector3(0.79, 0.35, 0.50).normalized(), 1.74))
    ]
    for pose in generic_poses:
        var freq := PackedInt32Array()
        freq.resize(9)
        for rotation in rotations:
            var top := Octa.top_value(pose * rotation)
            _expect(top >= 1 and top <= 8, "Single top face for generic pose")
            if top >= 1 and top <= 8:
                freq[top] += 1
        for face in range(1, 9):
            _expect(freq[face] == 3, "Exactly three rotations map to D8 face %d" % face)

    print("M3 D8 octahedron math: %d checks, %d failures" % [checks, failures])
    quit(0 if failures == 0 else 1)
