extends RefCounted
## Sculpted twenty-face visual assembly for exact rigid-body icosahedra.
## Faces and bevels are genuine triangles, not a wireframe of cylinders.
## Crucially the central numbered plane and world face normals are identical
## to the Jolt ConvexPolygonShape3D. No geometry affects the collider.
const INSET := 0.135
const CORNER_DEPTH := 0.065
const GOLD_INSET := 0.215
const GOLD_WIDTH := 0.0035

static func _triangle(t: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, outward: Vector3) -> void:
    if (b - a).cross(c - a).dot(outward) < 0.0:
        var tmp := b
        b = c
        c = tmp
    t.set_normal(outward)
    t.add_vertex(a)
    t.set_normal(outward)
    t.add_vertex(b)
    t.set_normal(outward)
    t.add_vertex(c)

static func _quad(t: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, d: Vector3, outward: Vector3) -> void:
    _triangle(t, a, b, c, outward)
    _triangle(t, a, c, d, outward)

static func face_planes(vertices: PackedVector3Array, faces: Array) -> ArrayMesh:
    var builder := SurfaceTool.new()
    builder.begin(Mesh.PRIMITIVE_TRIANGLES)
    for index in range(faces.size()):
        var f: Array = faces[index]
        var a: Vector3 = vertices[f[0]]
        var b: Vector3 = vertices[f[1]]
        var c: Vector3 = vertices[f[2]]
        var center := (a + b + c) / 3.0
        var outward := (b - a).cross(c - a).normalized()
        _triangle(builder, a.lerp(center, INSET), b.lerp(center, INSET), c.lerp(center, INSET), outward)
    return builder.commit()

static func chamfers(vertices: PackedVector3Array, faces: Array) -> ArrayMesh:
    var builder := SurfaceTool.new()
    builder.begin(Mesh.PRIMITIVE_TRIANGLES)
    for index in range(faces.size()):
        var f: Array = faces[index]
        var a: Vector3 = vertices[f[0]]
        var b: Vector3 = vertices[f[1]]
        var c: Vector3 = vertices[f[2]]
        var center := (a + b + c) / 3.0
        var outer := [a, b, c]
        var inner := [a.lerp(center, INSET), b.lerp(center, INSET), c.lerp(center, INSET)]
        for edge in range(3):
            var after := (edge + 1) % 3
            var p: Vector3 = inner[edge]
            var q: Vector3 = inner[after]
            var r: Vector3 = outer[after] * (1.0 - CORNER_DEPTH)
            var s: Vector3 = outer[edge] * (1.0 - CORNER_DEPTH)
            var cross_normal := (q - p).cross(r - p).normalized()
            var expected := ((p + q + r + s) * 0.25).normalized()
            if cross_normal.dot(expected) < 0.0:
                cross_normal = -cross_normal
            _quad(builder, p, q, r, s, cross_normal)
    return builder.commit()

static func inlaid_tracery(vertices: PackedVector3Array, faces: Array) -> ArrayMesh:
    ## Hairline geometry inset *within each triangular plane*.
    ## Never frames the wire edges in midair.
    var builder := SurfaceTool.new()
    builder.begin(Mesh.PRIMITIVE_TRIANGLES)
    for index in range(faces.size()):
        var f: Array = faces[index]
        var a: Vector3 = vertices[f[0]]
        var b: Vector3 = vertices[f[1]]
        var c: Vector3 = vertices[f[2]]
        var center := (a + b + c) / 3.0
        var normal := (b - a).cross(c - a).normalized()
        var trim := [
            a.lerp(center, GOLD_INSET),
            b.lerp(center, GOLD_INSET),
            c.lerp(center, GOLD_INSET)
        ]
        for edge in range(3):
            var p: Vector3 = trim[edge]
            var q: Vector3 = trim[(edge + 1) % 3]
            var offset: Vector3 = normal * 0.0028
            var inward: Vector3 = (center - (p + q) * 0.5).normalized() * GOLD_WIDTH
            _quad(builder, p + offset, q + offset, q + offset + inward, p + offset + inward, normal)
    return builder.commit()

static func bevel_material() -> StandardMaterial3D:
    var material := StandardMaterial3D.new()
    material.albedo_color = Color(0.125, 0.145, 0.18)
    material.metallic = 0.42
    material.roughness = 0.19
    material.clearcoat_enabled = true
    material.clearcoat = 0.54
    material.clearcoat_roughness = 0.14
    return material

static func gold_groove_material() -> StandardMaterial3D:
    var material := StandardMaterial3D.new()
    material.albedo_color = Color(0.38, 0.29, 0.16)
    material.metallic = 0.60
    material.roughness = 0.27
    material.emission_enabled = true
    material.emission = Color(0.14, 0.078, 0.025)
    material.emission_energy_multiplier = 0.18
    return material
