extends RefCounted
## High-fidelity visual *only* bevel on an otherwise exact Jolt BoxShape3D.
## Face centers stay on their original planes, so fixed 3D numerals still
## match the physical upper face and exact 1..6 symmetry of collision hull.

static func _tri(surface: SurfaceTool, p: Vector3, q: Vector3, r: Vector3, facing: Vector3) -> void:
    var a := p
    var b := q
    var c := r
    if (b - a).cross(c - a).dot(facing) < 0.0:
        var temp := b
        b = c
        c = temp
    for point in [a, b, c]:
        surface.set_normal(facing.normalized())
        surface.add_vertex(point)

static func _quad(surface: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, d: Vector3, outward: Vector3) -> void:
    _tri(surface, a, b, c, outward)
    _tri(surface, a, c, d, outward)

static func create(side_length: float, bevel_width: float = 0.095) -> ArrayMesh:
    var h := side_length * 0.5
    var t := h - bevel_width
    var surface := SurfaceTool.new()
    surface.begin(Mesh.PRIMITIVE_TRIANGLES)
    for axis in range(3):
        var axis_u := (axis + 1) % 3
        var axis_v := (axis + 2) % 3
        for sign in [-1.0, 1.0]:
            var n := Vector3.ZERO
            n[axis] = sign
            var u := Vector3.ZERO
            var v := Vector3.ZERO
            u[axis_u] = 1.0
            v[axis_v] = 1.0
            _quad(surface,
                n * h + u * t + v * t,
                n * h - u * t + v * t,
                n * h - u * t - v * t,
                n * h + u * t - v * t,
                n)
    for axis_a in range(3):
        for axis_b in range(axis_a + 1, 3):
            var axis_c := 3 - axis_a - axis_b
            for sa in [-1.0, 1.0]:
                for sb in [-1.0, 1.0]:
                    var a := Vector3.ZERO
                    var b := Vector3.ZERO
                    var c := Vector3.ZERO
                    a[axis_a] = sa
                    b[axis_b] = sb
                    c[axis_c] = 1.0
                    var normal := (a + b).normalized()
                    _quad(surface,
                        a * h + b * t + c * t,
                        a * t + b * h + c * t,
                        a * t + b * h - c * t,
                        a * h + b * t - c * t,
                        normal)
    for sx in [-1.0, 1.0]:
        for sy in [-1.0, 1.0]:
            for sz in [-1.0, 1.0]:
                var outward := Vector3(sx, sy, sz).normalized()
                _tri(surface,
                    Vector3(sx * h, sy * t, sz * t),
                    Vector3(sx * t, sy * h, sz * t),
                    Vector3(sx * t, sy * t, sz * h),
                    outward)
    return surface.commit()
