extends RefCounted
## Procedural, locally generated visual assets. No licensed textures or
## external service. All embellishments are NON-COLLIDING.
const EngravedGem = preload("res://src/visual/engraved_gem.gd")
const GOLD := Color(0.56, 0.41, 0.25)
const OBSIDIAN := Color(0.075, 0.085, 0.105)

static func velvet_material() -> StandardMaterial3D:
    var material := StandardMaterial3D.new()
    material.albedo_color = Color(1, 1, 1, 1)
    material.albedo_texture = _velvet_texture()
    material.normal_enabled = true
    material.normal_texture = _velvet_normal_texture()
    material.normal_scale = 0.42
    material.roughness = 0.96
    material.metallic = 0.0
    return material

static func _velvet_texture() -> ImageTexture:
    var texture := Image.create(256, 256, false, Image.FORMAT_RGBA8)
    var noise := FastNoiseLite.new()
    noise.seed = 57321
    noise.frequency = 0.075
    for y in range(256):
        for x in range(256):
            var grain: float = noise.get_noise_2d(float(x), float(y))
            var thread: float = sin(float(x) * 0.92 + float(y) * 0.12) * 0.006
            var fine: float = noise.get_noise_2d(float(x * 3 + 400), float(y * 3 - 700))
            var value := clampf(0.062 + grain * 0.025 + fine * 0.018 + thread, 0.029, 0.11)
            texture.set_pixel(x, y, Color(value * 0.83, value * 0.85, value, 1.0))
    texture.generate_mipmaps()
    return ImageTexture.create_from_image(texture)

static func _velvet_normal_texture() -> ImageTexture:
    # Tangent-space felt microfibers introduce real rough surface shading,
    # rather than painting decorative blotches on an otherwise flat plane.
    var texture := Image.create(256, 256, false, Image.FORMAT_RGBA8)
    var noise := FastNoiseLite.new()
    noise.seed = 57491
    noise.frequency = 0.11
    for y in range(256):
        for x in range(256):
            var nx: float = noise.get_noise_2d(float(x + 1), float(y)) - noise.get_noise_2d(float(x - 1), float(y))
            var ny: float = noise.get_noise_2d(float(x), float(y + 1)) - noise.get_noise_2d(float(x), float(y - 1))
            var fiber: float = sin(float(x) * 1.7 + float(y) * 0.09) * 0.075
            var n := Vector3(-nx * 0.8 - fiber, -ny * 0.8, 1.0).normalized()
            texture.set_pixel(x, y, Color(0.5 + n.x * 0.5, 0.5 + n.y * 0.5, 0.5 + n.z * 0.5, 1.0))
    texture.generate_mipmaps()
    return ImageTexture.create_from_image(texture)

static func obsidian_material() -> ShaderMaterial:
    var stone := ShaderMaterial.new()
    stone.shader = preload("res://src/visual/obsidian.gdshader")
    return stone

static func gold_material() -> StandardMaterial3D:
    var metal := StandardMaterial3D.new()
    metal.albedo_color = GOLD
    metal.metallic = 0.82
    metal.roughness = 0.23
    return metal

static func blackened_metal() -> StandardMaterial3D:
    var metal := StandardMaterial3D.new()
    metal.albedo_color = Color(0.095, 0.10, 0.115)
    metal.metallic = 0.74
    metal.roughness = 0.34
    return metal


static func _stone_pbr_for_glb(source: Material = null) -> StandardMaterial3D:
    # Clean polished volcanic glass. Unlike the high-frequency mineral
    # shader, this PBR response avoids zebra/moiré artifacts when GLB
    # triangulated face normals are rendered by Android/Mesa Mobile.
    var stone := StandardMaterial3D.new()
    stone.albedo_color = Color(0.082, 0.10, 0.13)
    stone.metallic = 0.10
    stone.roughness = 0.39
    stone.clearcoat_enabled = true
    stone.clearcoat = 0.23
    stone.clearcoat_roughness = 0.32
    stone.emission_enabled = true
    stone.emission = Color(0.050, 0.061, 0.079)
    stone.emission_energy_multiplier = 0.60
    if source is StandardMaterial3D:
        var original := source as StandardMaterial3D
        stone.albedo_texture = original.albedo_texture
        if stone.albedo_texture != null:
            # Dark tint is already baked into the albedo map. Multiplying by
            # another graphite color would make the imported D20 near black.
            stone.albedo_color = Color(1.0, 1.0, 1.0)
        stone.roughness_texture = original.roughness_texture
        if stone.roughness_texture != null:
            stone.roughness = 1.0
        stone.roughness_texture_channel = original.roughness_texture_channel
        stone.normal_enabled = original.normal_enabled
        stone.normal_texture = original.normal_texture
        stone.normal_scale = 0.28
    return stone

static func _gold_inset_for_glb() -> StandardMaterial3D:
    var gold := StandardMaterial3D.new()
    gold.albedo_color = Color(0.84, 0.56, 0.27)
    gold.metallic = 0.52
    gold.roughness = 0.36
    gold.clearcoat_enabled = true
    gold.clearcoat = 0.12
    gold.emission_enabled = true
    gold.emission = Color(0.17, 0.088, 0.026)
    gold.emission_energy_multiplier = 0.26
    return gold

static func _finish_glb_node(node: Node) -> void:
    # Godot Mobile/GL compatibility lighting needs a consistent material
    # response among all five dice. Apply to rendered surfaces only;
    # authored Boolean geometry, face IDs, and Jolt hull stay unchanged.
    if node is MeshInstance3D:
        var surface := node as MeshInstance3D
        if surface.name.begins_with("Sculpted_Obsidian"):
            var original: Material = surface.mesh.surface_get_material(0) if surface.mesh != null else null
            surface.material_override = _stone_pbr_for_glb(original)
        elif surface.name.begins_with("Recessed_Bronze"):
            surface.material_override = _gold_inset_for_glb()
    for child in node.get_children():
        _finish_glb_node(child)

static func _attach_blender_glb(die: RigidBody3D, sides: int) -> bool:
    ## GLB meshes are 100% VISUAL, never a physics hull or source of roll
    ## numbers. Their canonical geometry and face IDs are pinned by Blender
    ## CI; true Jolt collision remains in the original RigidBody.
    if die.get_node_or_null("BlenderRecessedGLB") != null:
        return true
    var path := "res://src/assets/generated/d20_boolean_engraved.glb" if sides == 20 else "res://src/assets/generated/d6_boolean_engraved.glb"
    if not ResourceLoader.exists(path):
        return false
    var packed: Resource = load(path)
    if not packed is PackedScene:
        push_warning("Validated Blender geometry import unavailable for D%d" % sides)
        return false
    var art := (packed as PackedScene).instantiate() as Node3D
    if art == null:
        push_warning("Blender geometry did not instantiate as Node3D for D%d" % sides)
        return false
    art.name = "BlenderRecessedGLB"
    _finish_glb_node(art)
    die.add_child(art)
    for child in die.get_children():
        if child == art:
            continue
        if child is MeshInstance3D or child is Label3D:
            child.visible = false
    return true

static func decorate_die(die: RigidBody3D, sides: int) -> void:
    # Dedicated sculptural D20/D6 assets replace the legacy overlay and
    # floating edge wires. The RigidBody3D and numeric metadata remain intact.
    if sides == 20 or sides == 6:
        if _attach_blender_glb(die, sides):
            return
        # Safe fallback for code-only checkouts without exported binary assets.
        EngravedGem.apply(die, sides)
        return
    ## The physics hull never changes. Metallic hairline inlays attach only
    ## to the graphics and share the die's physical orientation.
    var collision: CollisionShape3D
    for node in die.get_children():
        if node is CollisionShape3D:
            collision = node
        elif node is MeshInstance3D and node.name.begins_with("Obsidian"):
            node.material_override = obsidian_material()
        elif node is Label3D:
            node.modulate = Color(1.0, 0.80, 0.52)
            node.outline_modulate = Color(0.015, 0.015, 0.018)
            node.outline_size = 6
            node.shaded = false
    # D20 has real planar chamfers and in-face flush bronze engraving.
    # Do not layer a wireframe of cylinders over its physical facets.
    if sides != 6:
        return
    if collision == null:
        return
    var points := PackedVector3Array()
    if collision.shape is BoxShape3D:
        var half: Vector3 = (collision.shape as BoxShape3D).size * 0.5
        for sx in [-1.0, 1.0]:
            for sy in [-1.0, 1.0]:
                for sz in [-1.0, 1.0]:
                    points.append(Vector3(sx * half.x, sy * half.y, sz * half.z))
    elif collision.shape is ConvexPolygonShape3D:
        points = (collision.shape as ConvexPolygonShape3D).points
    if points.size() < 4:
        return
    var shortest := INF
    for i in range(points.size()):
        for j in range(i + 1, points.size()):
            shortest = minf(shortest, points[i].distance_to(points[j]))
    var gold := gold_material()
    var decoration := Node3D.new()
    decoration.name = "NonCollidingMetalInlay"
    die.add_child(decoration)
    var edge_count := 0
    for i in range(points.size()):
        for j in range(i + 1, points.size()):
            var delta: Vector3 = points[j] - points[i]
            if delta.length() > shortest * 1.012:
                continue
            var cylinder := CylinderMesh.new()
            cylinder.top_radius = 0.011 if sides == 6 else 0.0035
            cylinder.bottom_radius = 0.011 if sides == 6 else 0.0035
            cylinder.height = delta.length()
            cylinder.radial_segments = 6
            var edge := MeshInstance3D.new()
            edge.mesh = cylinder
            edge.material_override = gold
            edge.position = (points[j] + points[i]) * 0.5
            edge.quaternion = Quaternion(Vector3.UP, delta.normalized())
            decoration.add_child(edge)
            edge_count += 1
    if edge_count == 0:
        push_warning("Non-colliding visual edge set empty for D%d" % sides)
