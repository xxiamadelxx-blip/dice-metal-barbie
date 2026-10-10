extends SceneTree
## Geometry-contract checks for physically real, inward-recessed D20/D6 art.
## Existing Jolt numeric regressions remain separate and authoritative.
const D20 = preload("res://src/dice/d20_body.gd")
const D6 = preload("res://src/dice/d6_body.gd")
const Premium = preload("res://src/visual/premium_finish.gd")
const Ico = preload("res://src/core/icosahedron.gd")
const Cube = preload("res://src/core/cube_symmetry.gd")

var count := 0
var fails := 0

func _check(ok: bool, message: String) -> void:
    count += 1
    if not ok:
        fails += 1
        push_error(message)

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    for sides in [20, 6]:
        var die: RigidBody3D = D20.new() if sides == 20 else D6.new()
        root.add_child(die)
        await process_frame
        var shape: CollisionShape3D = die.get_node("IcosahedronCollision") if sides == 20 else die.get_node("SymmetricCubeCollision")
        var old_shape: Shape3D = shape.shape
        var old_mass := die.mass
        Premium.decorate_die(die, sides)
        Premium.decorate_die(die, sides)
        var art := die.get_node_or_null("RecessedGemAsset") as Node3D
        _check(art != null, "D%d must have dedicated engraved asset" % sides)
        if art == null:
            die.queue_free()
            continue
        _check(die.get_node("RecessedGemAsset") == art, "Art must be owned by die")
        _check(art.get_child_count() == sides + 5, "Exactly one TextMesh per face plus five shared sculptural surfaces")
        _check(shape.shape == old_shape, "D%d cannot replace or mutate Jolt collision hull" % sides)
        _check(is_equal_approx(die.mass, old_mass), "D%d cannot change physical mass" % sides)
        _check(die.get_node_or_null("NonCollidingMetalInlay") == null, "Floating gold edge wires prohibited")
        for node_name in ["StoneFaceRings", "PolishedChamferMesh", "RecessedPocketWalls", "RecessedPocketFloors", "PocketBronzeInlay"]:
            var node := art.get_node_or_null(node_name) as MeshInstance3D
            _check(node != null, "D%d missing %s" % [sides, node_name])
            if node != null:
                var min_vertices: int = int(sides) * (3 if node_name == "RecessedPocketFloors" else 6)
                _check(node.mesh.get_faces().size() >= min_vertices, "Mesh %s contains too few vertices" % node_name)
                _check(node.material_override != null, "Missing PBR material on %s" % node_name)
        var values: Array = []
        if sides == 20:
            for number in Ico.numbers():
                values.append(number)
        else:
            for number in Cube.D6_FACE_VALUES:
                values.append(number)
        for number in values:
            var glyph := art.get_node_or_null("EngravedNumber_%d" % number) as MeshInstance3D
            _check(glyph != null, "D%d numeral %d missing" % [sides, number])
            if glyph != null:
                _check(glyph.mesh is TextMesh, "D%d numeral must be an extruded real 3D TextMesh" % sides)
                var glyph_mesh := glyph.mesh as TextMesh
                _check(glyph_mesh.text == str(number), "D%d engraved number mapping mismatch" % sides)
                _check(glyph_mesh.depth > 0.0, "D%d engraved glyph requires 3D thickness" % sides)
                _check(glyph_mesh.get_faces().size() > 0, "D%d numeral %d must emit real renderable triangles" % [sides, number])
                var face_id: int = values.find(number)
                var expected_normal: Vector3 = Ico.face_normal(face_id) if sides == 20 else Cube.D6_FACE_NORMALS[face_id]
                var expected_center: Vector3 = Ico.face_center(face_id) if sides == 20 else expected_normal * (D6.SIDE * 0.5)
                var below_surface: float = (glyph.position - expected_center).dot(expected_normal)
                _check(absf(below_surface + 0.015) < 0.0005,
                    "D%d numeral %d must sit recessed inside stone" % [sides, number])
                _check(glyph.position.dot(glyph.basis.z) > 0.0, "Engraved glyph should remain on its outward face")
        die.queue_free()
        await process_frame
    print("M5 sculpted D20/D6 asset contracts: %d checks, %d FAIL" % [count, fails])
    quit(0 if fails == 0 else 1)
