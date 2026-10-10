extends SceneTree
## Exact tetrahedral geometry / apex reading rather than fictional top face.
const Tetra = preload("res://src/core/tetrahedron.gd")
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
    var pts := Tetra.vertices()
    _assert(pts.size() == 4, "Regular D4 needs four vertices")
    var distances: Array[float] = []
    for i in range(4):
        for j in range(i + 1, 4):
            distances.append(pts[i].distance_to(pts[j]))
    for dist in distances:
        _assert(absf(dist - distances[0]) < 0.0001, "All six edges must be equal")

    for opposite in range(4):
        var ids := Tetra.face_indices(opposite)
        _assert(ids.size() == 3, "D4 face must have three vertices")
        _assert(not ids.has(opposite), "Opposite point cannot belong to contact face")
        var n: Vector3 = Tetra.face_normal(opposite)
        _assert(n.dot(Tetra.face_center(opposite)) > 0.0, "Face normal must be outward")
        _assert(n.dot(pts[opposite]) < 0.0, "Contact face points AWAY from apex")
        for apex in range(4):
            if apex == opposite:
                continue
            var mark := Tetra.printed_position(apex, opposite)
            _assert((mark - pts[apex]).length() > 0.001, "Glyph must be inside triangle")
            _assert((mark - Tetra.face_center(opposite)).dot(n) > 0.001, "Glyph must be outside visible face")

    var rotations := Tetra.rotations()
    _assert(rotations.size() == 12, "Proper tetrahedral group must have order 12")
    var keys := {}
    for r in rotations:
        _assert(absf(r.determinant() - 1.0) < 0.0001, "Mirror rotations prohibited")
        keys[str(r)] = true
        for p in pts:
            var preserved := false
            for q in pts:
                if (r * p).distance_to(q) < 0.0001:
                    preserved = true
                    break
            _assert(preserved, "Rotation must preserve actual collision hull")
    _assert(keys.size() == 12, "12 unique rotations required")

    for pose in [
        Basis(Quaternion(Vector3(0.37, 0.49, 0.78).normalized(), 0.83)),
        Basis(Quaternion(Vector3(0.91, 0.22, 0.34).normalized(), 1.67))
    ]:
        var counts := PackedInt32Array()
        counts.resize(5)
        for sym in rotations:
            var value := Tetra.top_value(pose * sym)
            _assert(value >= 1 and value <= 4, "Apex must be well defined for generic pose")
            if value >= 1 and value <= 4:
                counts[value] += 1
        for value in range(1, 5):
            _assert(counts[value] == 3, "Each apex label must have 3 proper rotations")

    ## Identity has two equally high vertices: an ambiguous top reading.
    _assert(Tetra.top_value(Basis.IDENTITY) == -1, "Ambiguous apex must not fabricate result")
    print("M3 D4 tetrahedron geometry: %d checks, %d failed" % [checks, failed])
    quit(0 if failed == 0 else 1)
