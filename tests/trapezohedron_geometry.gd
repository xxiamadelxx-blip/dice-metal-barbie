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
        var edges := {}
        var min_area := INF
        var max_area := 0.0
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
            var d := vertices[indices[3]]
            _check((b-a).cross(c-a).dot(n) > 0.0, "D%d outward face winding" % sides)
            var area: float = 0.5 * ((b-a).cross(c-a).length() +
                (c-a).cross(d-a).length())
            min_area = minf(min_area, area)
            max_area = maxf(max_area, area)
            for corner in range(4):
                var va: int = indices[corner]
                var vb: int = indices[(corner+1)%4]
                var edge_key := "%d:%d" % [mini(va,vb),maxi(va,vb)]
                edges[edge_key] = int(edges.get(edge_key,0)) + 1
            # Convex hull proof for every claimed kite plane.
            for vertex in vertices:
                _check((vertex - center).dot(n) <= 0.0001,
                    "D%d invalid convex halfspace at face %d" % [sides,face])
            seen[labels[face]] = true
            var pose := Basis(Quaternion(n, Vector3.UP))
            _check(ShapeMath.top_value(sides, pose) == labels[face], "D%d upper face result wrong" % sides)
        _check(seen.size() == sides, "D%d missing or repeated labels" % sides)
        _check(min_area > 0.001, "D%d degenerate kite area" % sides)
        _check(max_area / min_area < 1.0001, "D%d inequivalent kite areas" % sides)
        _check(vertices.size() - edges.size() + sides == 2,
            "D%d failed Euler V-E+F=2" % sides)
        for edge_use in edges.values():
            _check(int(edge_use) == 2, "D%d open or nonmanifold edge" % sides)
        if sides == 10:
            var digits := ShapeMath.numbers(10)
            for i in range(5):
                var opposite := (i + 2) % 5 + 5
                _check(digits[i] % 10 + digits[opposite] % 10 == 9,
                    "D10 opposite printed faces must sum to 9")
        # The source of crypto-selected initial poses must be an actual
        # transitive set of 2n proper rotational symmetries.
        var orbit := {}
        var ring: int = sides / 2
        for turn_index in range(sides):
            var spin := TAU * float(turn_index % ring) / float(ring)
            var transform := Basis(Vector3.UP, spin)
            if turn_index >= ring:
                var axis := Vector3(cos(PI / float(sides)), 0.0,
                    sin(PI / float(sides))).normalized()
                transform = Basis(axis, PI) * transform
            var changed_normal: Vector3 = transform * ShapeMath.face_normal(sides, 0)
            var matched := -1
            for other_face in range(sides):
                if changed_normal.dot(ShapeMath.face_normal(sides, other_face)) > 0.99999:
                    matched = other_face
                    break
            _check(matched >= 0, "D%d rotation must preserve real faces" % sides)
            orbit[matched] = true
        _check(orbit.size() == sides, "D%d initial rotations must cover every face uniformly" % sides)
        for num in range(1, sides + 1):
            _check(seen.has(num), "D%d missing number %d" % [sides, num])
    print("M3 trapezohedron geometry: %d checks, %d failures" % [checks, failures])
    quit(0 if failures == 0 else 1)
