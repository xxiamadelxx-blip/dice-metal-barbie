extends SceneTree
## Geometry-contract checks for physically real, inward-recessed D20/D6 art.
## Existing Jolt numeric regressions remain separate and authoritative.
const D20 = preload("res://src/dice/d20_body.gd")
const D6 = preload("res://src/dice/d6_body.gd")
const D8 = preload("res://src/dice/d8_body.gd")
const D12 = preload("res://src/dice/d12_body.gd")
const D4 = preload("res://src/dice/d4_body.gd")
const Premium = preload("res://src/visual/premium_finish.gd")
const Ico = preload("res://src/core/icosahedron.gd")
const Cube = preload("res://src/core/cube_symmetry.gd")
const Sculpted = preload("res://src/visual/engraved_gem.gd")

var count := 0
var fails := 0

func _check(ok: bool, message: String) -> void:
    count += 1
    if not ok:
        fails += 1
        push_error(message)

func _initialize() -> void:
    call_deferred("_run")

func _imported_meshes(node: Node) -> Array[MeshInstance3D]:
    var found: Array[MeshInstance3D] = []
    if node is MeshInstance3D:
        found.append(node as MeshInstance3D)
    for child in node.get_children():
        found.append_array(_imported_meshes(child))
    return found


func _run() -> void:
    for sides in [20, 6, 8, 12, 4]:
        var die: RigidBody3D
        match sides:
            20: die = D20.new()
            6: die = D6.new()
            8: die = D8.new()
            12: die = D12.new()
            4: die = D4.new()
        root.add_child(die)
        await process_frame
        var collider_name: String = {20:"IcosahedronCollision",6:"SymmetricCubeCollision",
            8:"OctahedronCollision",12:"DodecahedronCollision",
            4:"TetrahedronCollision"}[sides]
        var shape := die.get_node(collider_name) as CollisionShape3D
        var old_shape: Shape3D = shape.shape
        var old_mass := die.mass
        Premium.decorate_die(die, sides)
        Premium.decorate_die(die, sides)
        var baked := die.get_node_or_null("BlenderRecessedGLB") as Node3D
        var glb_path := "res://src/assets/generated/d%d_boolean_engraved.glb" % sides
        _check(ResourceLoader.exists(glb_path), "M5 pinned Blender GLB missing for D%d" % sides)
        if baked != null:
            _check(shape.shape == old_shape, "Imported D%d GLB must not change Jolt collision resource" % sides)
            _check(is_equal_approx(die.mass, old_mass), "Imported D%d GLB must not change mass" % sides)
            _check(die.get_node_or_null("RecessedGemAsset") == null, "M5 GLB cannot draw twice with procedural asset")
            _check(die.get_node_or_null("NonCollidingMetalInlay") == null, "No floating cylinder outlines")
            var meshes := _imported_meshes(baked)
            var pbr_mesh: MeshInstance3D = null
            for item in meshes:
                if item.name.begins_with("Sculpted_Obsidian"):
                    pbr_mesh = item
            _check(pbr_mesh != null, "D%d obsidian art mesh must be present" % sides)
            if pbr_mesh != null and pbr_mesh.material_override is StandardMaterial3D:
                var mapped := pbr_mesh.material_override as StandardMaterial3D
                _check(mapped.albedo_texture != null, "D%d generated albedo texture not applied to real Godot mesh" % sides)
                _check(mapped.normal_enabled and mapped.normal_texture != null, "D%d tangent-space normal texture not applied" % sides)
                _check(mapped.roughness_texture != null, "D%d scalar-only roughness is not PBR art" % sides)
                # Independent material-contract gate for M5 light-response
                # correction: real GLB normal/roughness remain attached;
                # emitting a uniform blue-grey color is not polished stone.
                _check(not mapped.emission_enabled,
                    "D%d fake emissive wash destroys true facet shading" % sides)
                _check(mapped.clearcoat_enabled and mapped.clearcoat >= 0.50,
                    "D%d obsidian lacks a distinct polish/reflection lobe" % sides)
                _check(mapped.clearcoat_roughness <= 0.20,
                    "D%d clearcoat is too matte for premium stone" % sides)
                _check(mapped.metallic >= 0.15 and mapped.metallic <= 0.35,
                    "D%d obsidian metallic response outside physical-art budget" % sides)
                _check(mapped.roughness > 0.60 and mapped.roughness < 0.90,
                    "D%d GLB roughness texture must retain real variation" % sides)
            _check(meshes.size() == 2, "D%d GLB must contain separate stone and bronze geometry" % sides)
            for mesh_node in meshes:
                _check(mesh_node.mesh != null and mesh_node.mesh.get_surface_count() > 0,
                    "D%d imported GLB mesh has no render surfaces" % sides)
                _check(mesh_node.material_override != null,
                    "D%d imported GLB material override missing in Godot renderer" % sides)
                if mesh_node.mesh != null and mesh_node.mesh.get_surface_count() > 0:
                    _check(mesh_node.mesh.surface_get_material(0) != null,
                        "D%d GLB lacks imported physical material" % sides)
            var legacy_name: String = {20:"ObsidianD20",6:"Obsidian",
                8:"ObsidianD8",12:"ObsidianD12",4:"ObsidianD4"}[sides]
            var original_stone := die.get_node_or_null(legacy_name)
            _check(original_stone != null and not original_stone.visible, "Legacy die geometry should be hidden")
            var label_name := "Apex_1_OnFace_1" if sides == 4 else "Face_1"
            var original_label := die.get_node_or_null(label_name) as Label3D
            _check(original_label != null and not original_label.visible, "Face mapping retained but old label hidden")
            die.queue_free()
            await process_frame
            continue
        if sides in [4,8,12]:
            _check(false, "D%d authored GLB unavailable; cannot promote fallback as premium art" % sides)
            die.queue_free()
            await process_frame
            continue
        var art := die.get_node_or_null("RecessedGemAsset") as Node3D
        _check(art != null, "D%d must have dedicated engraved asset" % sides)
        if art == null:
            die.queue_free()
            continue
        _check(die.get_node("RecessedGemAsset") == art, "Art must be owned by die")
        _check(art.get_child_count() == sides + 5, "Exactly one TextMesh per face plus five shared sculptural surfaces")
        _check(Sculpted.RECESS_DEPTH <= 0.01, "Pocket cannot visually become a black hole")
        _check(Sculpted.FACE_PLATE >= 0.9, "Bevel cannot swallow broad face planes")
        var floor_node := art.get_node("RecessedPocketFloors") as MeshInstance3D
        _check(floor_node.material_override is ShaderMaterial, "Recess floor must have visible obsidian, not pitch-black void")
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
                _check(absf(below_surface + 0.005) < 0.0005,
                    "D%d numeral %d must sit recessed inside stone" % [sides, number])
                _check(glyph.position.dot(glyph.basis.z) > 0.0, "Engraved glyph should remain on its outward face")
        die.queue_free()
        await process_frame
    print("M5 sculpted D20/D6/D8/D12/D4 asset contracts: %d checks, %d FAIL" % [count, fails])
    quit(0 if fails == 0 else 1)
