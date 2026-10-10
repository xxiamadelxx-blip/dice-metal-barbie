extends SceneTree
const ShapeMath = preload("res://src/core/trapezohedron.gd")
var checks := 0
var failures := 0

func _initialize() -> void:
    call_deferred("_run")

func _check(ok: bool, reason: String) -> void:
    checks += 1
    if not ok:
        failures += 1
        push_error(reason)

func _run() -> void:
    for sides in [10, 100]:
        var vertices := ShapeMath.vertices(sides)
        _check(vertices.size() == sides + 2, "D%d dual needs exactly N+2 vertices" % sides)
        var seen := {}
        var labels := ShapeMath.numbers(sides)
        _check(labels.size() == sides, "D%d requires one label per physical face" % sides)
        for face in range(sides):
            var indices := ShapeMath.face_indices(sides, face)
            _check(indices.size() == 4, "D%d face %d must be a real four-corner kite" % [sides, face])
            if indices.size() != 4:
                continue
            var n := ShapeMath.face_normal(sides, face)
            var center := ShapeMath.face_center(sides, face)
            _check(absf(n.length() - 1.0) < 0.001, "D%d unit normal" % sides)
            _check(center.dot(n) > 0.0, "D%d outward normal" % sides)
            for idx in indices:
                _check(idx >= 0 and idx < vertices.size(), "D%d vertex index in range" % sides)
                _check(absf((vertices[idx] - center).dot(n)) < 0.001, "D%d kite is nonplanar" % sides)
            var a := vertices[indices[0]]
            var b := vertices[indices[1]]
            var c := vertices[indices[2]]
            _check((b-a).cross(c-a).dot(n) > 0.0, "D%d outward face winding" % sides)
            seen[labels[face]] = true
            var pose := Basis(Quaternion(n, Vector3.UP))
            _check(ShapeMath.top_value(sides, pose) == labels[face], "D%d upper face result wrong" % sides)
        _check(seen.size() == sides, "D%d missing or repeated labels" % sides)
        for num in range(1, sides + 1):
            _check(seen.has(num), "D%d missing number %d" % [sides, num])
    print("M3 trapezohedron geometry: %d checks, %d failures" % [checks, failures])
    quit(0 if failures == 0 else 1)
