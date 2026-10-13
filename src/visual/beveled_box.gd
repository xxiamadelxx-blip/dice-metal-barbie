extends RefCounted
## VISUAL-only bevelled rectangular ebony rail, 1:1 world-unit corners.
## Keep original rail StaticBody3D BoxShape3D, collision AABB and mass.
## Separate face normals make a narrow studio light-edge without adding
## dozens of unnecessary triangles or changing offline Android performance.

static func _tri(s: SurfaceTool, a: Vector3, b: Vector3, c: Vector3,
        outward: Vector3) -> void:
    var bb := b
    var cc := c
    if (bb-a).cross(cc-a).dot(outward) < 0.0:
        bb = c
        cc = b
    for pt in [a,bb,cc]:
        s.set_normal(outward.normalized())
        s.add_vertex(pt)

static func _quad(s: SurfaceTool, a: Vector3,b: Vector3,
        c: Vector3,d: Vector3,n: Vector3) -> void:
    _tri(s,a,b,c,n)
    _tri(s,a,c,d,n)

static func create(dimensions: Vector3, bevel: float = 0.052) -> ArrayMesh:
    var h := dimensions * 0.5
    var bevel_actual := minf(bevel,minf(h.x,minf(h.y,h.z))*0.60)
    var t := h - Vector3.ONE * bevel_actual
    var s := SurfaceTool.new()
    s.begin(Mesh.PRIMITIVE_TRIANGLES)
    for axis in range(3):
        var u_axis := (axis+1)%3
        var v_axis := (axis+2)%3
        var u := Vector3.ZERO
        var v := Vector3.ZERO
        u[u_axis] = 1.0
        v[v_axis] = 1.0
        for sign in [-1.0,1.0]:
            var n := Vector3.ZERO
            n[axis] = sign
            var center := n*h[axis]
            _quad(s,center+u*t[u_axis]+v*t[v_axis],
                center-u*t[u_axis]+v*t[v_axis],
                center-u*t[u_axis]-v*t[v_axis],
                center+u*t[u_axis]-v*t[v_axis],n)
    for axis_a in range(3):
        for axis_b in range(axis_a+1,3):
            var axis_c := 3-axis_a-axis_b
            for sa in [-1.0,1.0]:
                for sb in [-1.0,1.0]:
                    var a := Vector3.ZERO
                    var bv := Vector3.ZERO
                    var c := Vector3.ZERO
                    a[axis_a] = sa
                    bv[axis_b] = sb
                    c[axis_c] = 1.0
                    var n := (a+bv).normalized()
                    _quad(s,
                        a*h[axis_a]+bv*t[axis_b]+c*t[axis_c],
                        a*t[axis_a]+bv*h[axis_b]+c*t[axis_c],
                        a*t[axis_a]+bv*h[axis_b]-c*t[axis_c],
                        a*h[axis_a]+bv*t[axis_b]-c*t[axis_c],n)
    for sx in [-1.0,1.0]:
        for sy in [-1.0,1.0]:
            for sz in [-1.0,1.0]:
                var n := Vector3(sx,sy,sz).normalized()
                _tri(s,Vector3(sx*h.x,sy*t.y,sz*t.z),
                    Vector3(sx*t.x,sy*h.y,sz*t.z),
                    Vector3(sx*t.x,sy*t.y,sz*h.z),n)
    return s.commit()
