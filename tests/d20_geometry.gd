extends SceneTree
## Exhaustive geometry checks for regular D20 and 60 proper symmetries.
## Does NOT prove behavior of the later Jolt RigidBody3D.

const Ico = preload("res://src/core/icosahedron.gd")
var checks := 0
var failed := 0

func _initialize() -> void:
    call_deferred("_run")

func _assert(ok: bool, message: String) -> void:
    checks += 1
    if not ok:
        failed += 1
        push_error(message)

func _run() -> void:
    var vertices := Ico.vertices()
    _assert(vertices.size() == 12, "D20 has 12 vertices")
    _assert(Ico.FACES.size() == 20, "D20 has 20 faces")
    var values := Ico.numbers()
    _assert(values.size() == 20, "D20 has 20 numbered faces")
    var numbers_found := {}
    for val in values:
        numbers_found[val] = true
    _assert(numbers_found.size() == 20, "Each D20 number 1..20 appears once")
    for val in range(1, 21):
        _assert(numbers_found.has(val), "D20 numeral missing %d" % val)

    for i in range(20):
        var n: Vector3 = Ico.face_normal(i)
        _assert(n.dot(Ico.face_center(i)) > 0, "Face %d winding must be outward" % i)
        var antipodal := -1
        for j in range(20):
            if n.dot(Ico.face_normal(j)) < -0.999:
                antipodal = j
                break
        _assert(antipodal >= 0, "Face %d missing opposite" % i)
        if antipodal >= 0:
            _assert(values[i] + values[antipodal] == 21, "Opposite D20 faces must sum to 21")

    var rotations := Ico.proper_rotations()
    _assert(rotations.size() == 60, "D20 has 60 proper rotations")
    var keys := {}
    for r in rotations:
        _assert(absf(r.determinant() - 1.0) < 0.0001, "Proper rotation determinant +1")
        var signature := str(r)
        keys[signature] = true
        for p in vertices:
            var transformed: Vector3 = r * p
            var matched := false
            for q in vertices:
                if transformed.distance_to(q) < 0.0001:
                    matched = true
                    break
            _assert(matched, "Rotation must preserve icosahedron collision hull")
    _assert(keys.size() == 60, "All 60 rotations distinct")

    ## Use generic base orientations, avoiding vertices pointing exactly up.
    var poses := [
        Basis(Quaternion(Vector3(0.31, 0.51, 0.74).normalized(), 0.78)),
        Basis(Quaternion(Vector3(0.93, 0.28, 0.19).normalized(), 1.39))
    ]
    for pose in poses:
        var count := PackedInt32Array()
        count.resize(21)
        for r in rotations:
            var face := Ico.top_face(pose * r)
            _assert(face >= 0, "Generic pose must have a single upper face")
            if face >= 0:
                count[values[face]] += 1
        for number in range(1, 21):
            _assert(count[number] == 3, "Proper icosahedral symmetries must evenly permute D20 number %d" % number)

    print("M3 D20 geometry and symmetry: %d checks, %d failed" % [checks, failed])
    quit(0 if failed == 0 else 1)
