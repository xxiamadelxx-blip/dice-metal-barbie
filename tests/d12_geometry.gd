extends SceneTree
## Mathematical verification of regular 12-faced dodecahedron.
const Dodeca = preload("res://src/core/dodecahedron.gd")
var checked := 0
var failed := 0

func _initialize() -> void:
    call_deferred("_run")

func _test(ok: bool, detail: String) -> void:
    checked += 1
    if not ok:
        failed += 1
        push_error(detail)

func _run() -> void:
    var points := Dodeca.vertices()
    _test(points.size() == 20, "D12 has 20 vertices")
    var numbers := Dodeca.numbers()
    _test(numbers.size() == 12, "D12 has 12 numbers")
    var seen := {}
    for i in range(12):
        var ids := Dodeca.face_indices(i)
        var normal := Dodeca.face_normal(i)
        _test(ids.size() == 5, "Each D12 face must be a pentagon")
        var center := Dodeca.face_center(i)
        _test(center.dot(normal) > 0, "Normal must point outward")
        var a: Vector3 = points[ids[0]]
        var b: Vector3 = points[ids[1]]
        var c: Vector3 = points[ids[2]]
        _test((b - a).cross(c - a).dot(normal) > 0, "Pentagon winding must be outward")
        for vertex_id in ids:
            var vertex: Vector3 = points[vertex_id]
            _test(absf((vertex - a).dot(normal)) < 0.0001, "Pentagon must be planar")
        var opposite := -1
        for j in range(12):
            if normal.dot(Dodeca.face_normal(j)) < -0.999:
                opposite = j
                break
        _test(opposite >= 0, "Missing antipodal face")
        if opposite >= 0:
            _test(numbers[i] + numbers[opposite] == 13, "Opposite D12 face numbers must sum to 13")
        seen[numbers[i]] = true
    _test(seen.size() == 12, "All twelve numerals unique")
    for i in range(1, 13):
        _test(seen.has(i), "Missing value %d" % i)

    var rotations := Dodeca.rotations()
    _test(rotations.size() == 60, "D12 has 60 proper rotational symmetries")
    var unique := {}
    for rotation in rotations:
        unique[str(rotation)] = true
        _test(absf(rotation.determinant() - 1.0) < 0.0001, "Rotation must be proper")
        for point in points:
            var rotated: Vector3 = rotation * point
            var matched := false
            for candidate in points:
                if rotated.distance_to(candidate) < 0.0001:
                    matched = true
                    break
            _test(matched, "Rotation does not preserve dodecahedral vertices")
    _test(unique.size() == 60, "Rotation group must have 60 distinct members")

    var poses := [
        Basis(Quaternion(Vector3(0.33, 0.5, 0.8).normalized(), 0.77)),
        Basis(Quaternion(Vector3(0.83, 0.3, 0.47).normalized(), 1.13))
    ]
    for pose in poses:
        var occurrences := PackedInt32Array()
        occurrences.resize(13)
        for symmetry in rotations:
            var value: int = Dodeca.top_value(pose * symmetry)
            _test(value >= 1 and value <= 12, "Unique result required for generic pose")
            if value >= 1 and value <= 12:
                occurrences[value] += 1
        for value in range(1, 13):
            _test(occurrences[value] == 5, "Each D12 face has five equivalent rotations")

    print("M3 D12 geometry: %d checks, %d failures" % [checked, failed])
    quit(0 if failed == 0 else 1)
