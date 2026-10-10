extends RefCounted
## Real, connected beveled polygonal gem shell from *exact* dice hull vertices.
## Supports triangles (D4/D8/D20) and planar pentagons (D12).
## The original Jolt collision hull, top-face normals and face-number mapping
## remain untouched. Unlike the earlier floating metal rods, each facet has
## real shoulder quads and dark recessed bronze hairlines inside the face.
const INSET := 0.125
const CORNER_DEPTH := 0.056
const GOLD_INSET := 0.195
const GOLD_WIDTH := 0.0038

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

static func _face_center(vertices: PackedVector3Array, f: Variant) -> Vector3:
    var center := Vector3.ZERO
    for j in range(f.size()):
        center += vertices[f[j]]
    return center / float(f.size())

static func _normal(vertices: PackedVector3Array, f: Variant) -> Vector3:
    var a: Vector3 = vertices[f[0]]
    var b: Vector3 = vertices[f[1]]
    var c: Vector3 = vertices[f[2]]
    var normal := (b - a).cross(c - a).normalized()
    if normal.dot(_face_center(vertices, f)) < 0.0:
        normal = -normal
    return normal

static func face_planes(vertices: PackedVector3Array, faces: Array) -> ArrayMesh:
    var builder := SurfaceTool.new()
    builder.begin(Mesh.PRIMITIVE_TRIANGLES)
    for i in range(faces.size()):
        var f = faces[i]
        var center := _face_center(vertices, f)
        var normal := _normal(vertices, f)
        var poly: Array[Vector3] = []
        for j in range(f.size()):
            poly.append(vertices[f[j]].lerp(center, INSET))
        for j in range(1, poly.size() - 1):
            _triangle(builder, poly[0], poly[j], poly[j + 1], normal)
    return builder.commit()

static func chamfers(vertices: PackedVector3Array, faces: Array) -> ArrayMesh:
    var builder := SurfaceTool.new()
    builder.begin(Mesh.PRIMITIVE_TRIANGLES)
    for i in range(faces.size()):
        var f = faces[i]
        var center := _face_center(vertices, f)
        for j in range(f.size()):
            var k := (j + 1) % f.size()
            var p: Vector3 = vertices[f[j]].lerp(center, INSET)
            var q: Vector3 = vertices[f[k]].lerp(center, INSET)
            var r: Vector3 = vertices[f[k]] * (1.0 - CORNER_DEPTH)
            var s: Vector3 = vertices[f[j]] * (1.0 - CORNER_DEPTH)
            var cross_normal := (q - p).cross(r - p).normalized()
            var expected := ((p + q + r + s) * 0.25).normalized()
            if cross_normal.dot(expected) < 0.0:
                cross_normal = -cross_normal
            _quad(builder, p, q, r, s, cross_normal)
    return builder.commit()

static func inlaid_tracery(vertices: PackedVector3Array, faces: Array) -> ArrayMesh:
    var builder := SurfaceTool.new()
    builder.begin(Mesh.PRIMITIVE_TRIANGLES)
    for i in range(faces.size()):
        var f = faces[i]
        var center := _face_center(vertices, f)
        var normal := _normal(vertices, f)
        var border: Array[Vector3] = []
        for j in range(f.size()):
            border.append(vertices[f[j]].lerp(center, GOLD_INSET))
        for j in range(border.size()):
            var p: Vector3 = border[j]
            var q: Vector3 = border[(j + 1) % border.size()]
            var lifted: Vector3 = normal * 0.0031
            var toward_center := (center - (p + q) * 0.5).normalized() * GOLD_WIDTH
            _quad(builder, p + lifted, q + lifted, q + lifted + toward_center,
                p + lifted + toward_center, normal)
    return builder.commit()

static func bevel_material() -> StandardMaterial3D:
    var material := StandardMaterial3D.new()
    material.albedo_color = Color(0.115, 0.135, 0.18)
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
