extends RefCounted
## Mesh-based art replacement for D20 and D6. The independent physics bodies,
## their symmetric collision hulls, and numbered-face decisions are unchanged.
##
## Each facet is real geometry: planar obsidian, polished chamfer shoulders,
## an open recessed pocket, an actual pocket wall and floor, and a small
## extruded metallic TextMesh *inside* the pocket rather than a floating Label3D.
## No remote assets, raster number fakes, gameplay mass, or collision added.

const Ico = preload("res://src/core/icosahedron.gd")
const Cube = preload("res://src/core/cube_symmetry.gd")
const RECESS_DEPTH := 0.008
const FACE_PLATE := 0.935
const POCKET_SCALE := 0.41
const POCKET_GOLD_SCALE := 0.425
const RIM_SCALE := 0.976

static func _tri(s: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, outward: Vector3) -> void:
    var x := b
    var y := c
    if (x - a).cross(y - a).dot(outward) < 0.0:
        x = c
        y = b
    for point in [a, x, y]:
        s.set_normal(outward.normalized())
        s.add_vertex(point)

static func _quad(s: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, d: Vector3, outward: Vector3) -> void:
    _tri(s, a, b, c, outward)
    _tri(s, a, c, d, outward)

static func _facets_of_cube() -> Dictionary:
    var vertices := PackedVector3Array()
    var faces: Array = []
    var numbers: Array = []
    var h := 0.61
    for i in range(6):
        var n: Vector3 = Cube.D6_FACE_NORMALS[i]
        var u := Vector3.RIGHT if absf(n.x) < 0.5 else Vector3.FORWARD
        var v := n.cross(u)
        var center := n * h
        var first := vertices.size()
        vertices.append(center - u * h - v * h)
        vertices.append(center + u * h - v * h)
        vertices.append(center + u * h + v * h)
        vertices.append(center - u * h + v * h)
        faces.append([first, first + 1, first + 2, first + 3])
        numbers.append(Cube.D6_FACE_VALUES[i])
    return {"vertices": vertices, "faces": faces, "numbers": numbers}

static func _obsidian() -> ShaderMaterial:
    var material := ShaderMaterial.new()
    material.shader = preload("res://src/visual/obsidian.gdshader")
    return material

static func _edge_material() -> StandardMaterial3D:
    var material := StandardMaterial3D.new()
    material.albedo_color = Color(0.087, 0.104, 0.139)
    material.metallic = 0.35
    material.roughness = 0.17
    material.clearcoat_enabled = true
    material.clearcoat = 0.7
    material.clearcoat_roughness = 0.12
    return material

static func _wall_material() -> StandardMaterial3D:
    var material := StandardMaterial3D.new()
    material.albedo_color = Color(0.019, 0.023, 0.031)
    material.metallic = 0.22
    material.roughness = 0.39
    return material

static func _gold_material() -> StandardMaterial3D:
    var material := StandardMaterial3D.new()
    material.albedo_color = Color(0.64, 0.43, 0.20)
    material.metallic = 0.82
    material.roughness = 0.29
    return material

static func _mesh(stage: Node3D, node_name: String, tool: SurfaceTool, material: Material) -> void:
    var node := MeshInstance3D.new()
    node.name = node_name
    node.mesh = tool.commit()
    node.material_override = material
    stage.add_child(node)

static func apply(die: RigidBody3D, sides: int) -> void:
    if sides != 6 and sides != 20:
        return
    if die.get_node_or_null("RecessedGemAsset") != null:
        return

    # Keep the original nodes (and label metadata) for all verified physics
    # and numeral-mapping tests. Only the renderer-visible meshes are replaced.
    for child in die.get_children():
        if child is MeshInstance3D or child is Label3D:
            child.visible = false

    var stage := Node3D.new()
    stage.name = "RecessedGemAsset"
    die.add_child(stage)

    var vertices: PackedVector3Array
    var faces: Array
    var numbers: Array = []
    if sides == 20:
        vertices = Ico.vertices()
        faces = Ico.FACES
        for number in Ico.numbers():
            numbers.append(number)
    else:
        var cube := _facets_of_cube()
        vertices = cube["vertices"]
        faces = cube["faces"]
        numbers = cube["numbers"]

    var facet := SurfaceTool.new()
    var chamfer := SurfaceTool.new()
    var pocket_wall := SurfaceTool.new()
    var pocket_floor := SurfaceTool.new()
    var pocket_trim := SurfaceTool.new()
    for surface in [facet, chamfer, pocket_wall, pocket_floor, pocket_trim]:
        surface.begin(Mesh.PRIMITIVE_TRIANGLES)

    for index in range(faces.size()):
        var corners: Array = faces[index]
        var center := Vector3.ZERO
        for vertex_index in corners:
            center += vertices[vertex_index]
        center /= float(corners.size())

        var normal := (vertices[corners[1]] - vertices[corners[0]]).cross(
            vertices[corners[2]] - vertices[corners[0]]).normalized()
        if normal.dot(center) < 0.0:
            normal = -normal
        var rim: Array[Vector3] = []
        var plate: Array[Vector3] = []
        var recess: Array[Vector3] = []
        var gold_outline: Array[Vector3] = []
        for vertex_index in corners:
            var p: Vector3 = vertices[vertex_index]
            rim.append(p * RIM_SCALE)
            plate.append(center.lerp(p, FACE_PLATE))
            recess.append(center.lerp(p, POCKET_SCALE))
            gold_outline.append(center.lerp(p, POCKET_GOLD_SCALE) + normal * 0.0008)

        var floor_points: Array[Vector3] = []
        for p in recess:
            floor_points.append(p - normal * RECESS_DEPTH)

        for k in range(corners.size()):
            var next := (k + 1) % corners.size()
            var shoulder_normal: Vector3 = (rim[k] + rim[next] + plate[k] + plate[next]).normalized()
            # Each closed face has physically connected outer and inner
            # polygons. The face center is deliberately not covered: the
            # cavity is real, not merely darker paint over a solid triangle.
            _quad(chamfer, plate[k], plate[next], rim[next], rim[k], shoulder_normal)
            _quad(facet, plate[k], plate[next], gold_outline[next], gold_outline[k], normal)
            _quad(pocket_trim, gold_outline[k], gold_outline[next],
                recess[next] + normal * 0.0009, recess[k] + normal * 0.0009, normal)
            _quad(pocket_wall, recess[k], recess[next],
                floor_points[next], floor_points[k], (center - recess[k]).normalized())

        for k in range(1, corners.size() - 1):
            _tri(pocket_floor, floor_points[0], floor_points[k], floor_points[k + 1], normal)

        var text_shape := TextMesh.new()
        text_shape.text = str(numbers[index])
        # Godot ships a vector fallback font; no third-party font license,
        # no committed font binary, no remote download during runtime.
        text_shape.font = ThemeDB.fallback_font
        text_shape.font_size = 60
        text_shape.pixel_size = 0.0029 if sides == 20 else 0.0053
        text_shape.depth = 0.006
        text_shape.curve_step = 0.9
        var glyph := MeshInstance3D.new()
        glyph.name = "EngravedNumber_%d" % numbers[index]
        glyph.mesh = text_shape
        glyph.material_override = _gold_material()
        # Real extruded glyph lies BELOW the outer facet and above the
        # recessed floor, so it cannot visually float on a face.
        glyph.position = center - normal * 0.005
        var up := Vector3.BACK if absf(normal.y) > 0.7 else Vector3.UP
        glyph.basis = Basis.looking_at(normal, up, true)
        stage.add_child(glyph)

    _mesh(stage, "StoneFaceRings", facet, _obsidian())
    _mesh(stage, "PolishedChamferMesh", chamfer, _edge_material())
    _mesh(stage, "RecessedPocketWalls", pocket_wall, _wall_material())
    _mesh(stage, "RecessedPocketFloors", pocket_floor, _obsidian())
    _mesh(stage, "PocketBronzeInlay", pocket_trim, _gold_material())
