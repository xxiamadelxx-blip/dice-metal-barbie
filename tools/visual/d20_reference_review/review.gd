extends SceneTree

var output_folder := "res://evidence"
var cast_shadows := true
var disable_lod := false
var balanced_studio := false
var refined_studio := false
var final_studio := false
var restore_authored_clearcoat := false
var authored_materials: Dictionary = {}
var source_path := "res://d20_obsidian_gold.glb"
var world: Node3D
var model: Node3D
var camera: Camera3D
var environment: Environment
var material_receipts: Array[Dictionary] = []

func _initialize() -> void:
    for argument in OS.get_cmdline_user_args():
        if argument.begins_with("--output="):
            output_folder = "res://evidence/" + argument.trim_prefix("--output=")
        if argument.begins_with("--source="):
            source_path = "res://" + argument.trim_prefix("--source=").get_file()
        if argument == "--no-shadows":
            cast_shadows = false
        if argument == "--disable-lod":
            disable_lod = true
        if argument == "--balanced-studio":
            balanced_studio = true
        if argument == "--refined-studio":
            balanced_studio = true
            refined_studio = true
        if argument == "--final-studio":
            balanced_studio = true
            refined_studio = true
            final_studio = true
        if argument == "--restore-clearcoat":
            restore_authored_clearcoat = true
    call_deferred("_run")

func _run() -> void:
    DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output_folder))
    world = Node3D.new()
    root.add_child(world)
    root.size = Vector2i(768, 768)
    root.msaa_3d = Viewport.MSAA_4X
    if disable_lod:
        root.mesh_lod_threshold = 0.0
    root.transparent_bg = false
    var packed := load(source_path) as PackedScene
    assert(packed != null, "Author-provided GLB did not import")
    model = packed.instantiate() as Node3D
    assert(model != null, "GLB did not instantiate")
    # Original source bytes, meshes, UVs and authored materials stay intact.
    # This is a frozen art review, not a simulated or forced dice outcome.
    model.position = Vector3(0.0, 0.796, 0.0)
    world.add_child(model)
    if restore_authored_clearcoat:
        _read_authored_materials()
        _restore_clearcoat(model)
    _inspect_materials(model)
    assert(material_receipts.size() == 23, "Unexpected GLB mesh count")

    var floor := MeshInstance3D.new()
    floor.name = "NeutralReviewFloor"
    var plane := PlaneMesh.new()
    plane.size = Vector2(200, 200)
    floor.mesh = plane
    var matte := StandardMaterial3D.new()
    matte.albedo_color = Color(0.080, 0.118, 0.097)
    if balanced_studio:
        matte.albedo_color = Color(0.16, 0.27, 0.23)
    if refined_studio:
        matte.albedo_color = Color(0.095, 0.16, 0.135)
    if final_studio:
        matte.albedo_color = Color(0.13, 0.205, 0.175)
    matte.roughness = 0.92
    matte.metallic = 0.0
    floor.material_override = matte
    world.add_child(floor)

    var env_node := WorldEnvironment.new()
    environment = Environment.new()
    environment.background_mode = Environment.BG_COLOR
    environment.background_color = Color(0.08, 0.118, 0.097)
    environment.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
    environment.ambient_light_energy = 0.38
    if balanced_studio:
        environment.ambient_light_energy = 0.85
    if refined_studio:
        environment.ambient_light_energy = 0.65
    environment.reflected_light_source = Environment.REFLECTION_SOURCE_SKY
    environment.tonemap_mode = Environment.TONE_MAPPER_ACES
    var sky := Sky.new()
    sky.radiance_size = Sky.RADIANCE_SIZE_512
    var sky_material := PanoramaSkyMaterial.new()
    sky_material.panorama = _studio_panorama()
    sky.sky_material = sky_material
    environment.sky = sky
    env_node.environment = environment
    world.add_child(env_node)

    var key := DirectionalLight3D.new()
    key.name = "StudioKey"
    key.rotation_degrees = Vector3(-55, -38, 0)
    key.light_color = Color(1.0, 0.92, 0.79)
    key.light_energy = 1.35
    key.shadow_enabled = cast_shadows
    key.directional_shadow_max_distance = 12.0
    key.shadow_normal_bias = 0.12
    key.shadow_bias = 0.025
    if balanced_studio:
        key.rotation_degrees = Vector3(-72, -38, 0)
        key.light_color = Color(1.0, 0.97, 0.93)
        key.light_energy = 2.0
        key.shadow_normal_bias = 0.02
        key.shadow_bias = 0.02
        key.shadow_blur = 2.0
        key.directional_shadow_mode = DirectionalLight3D.SHADOW_ORTHOGONAL
    if refined_studio:
        key.light_energy = 1.0
    if final_studio:
        key.rotation_degrees = Vector3(-58, -38, 0)
        key.light_energy = 0.9
        key.shadow_blur = 1.0
    world.add_child(key)

    var fill := DirectionalLight3D.new()
    fill.name = "CoolFill"
    fill.rotation_degrees = Vector3(-40, 142, 0)
    fill.light_color = Color(0.76, 0.86, 1.0)
    fill.light_energy = 0.28
    fill.shadow_enabled = false
    if balanced_studio:
        fill.rotation_degrees = Vector3(-42, 130, 0)
        fill.light_color = Color(0.94, 0.98, 1.0)
        fill.light_energy = 0.65
    if refined_studio:
        fill.light_energy = 0.45
    if final_studio:
        fill.light_energy = 0.3
    world.add_child(fill)

    camera = Camera3D.new()
    camera.projection = Camera3D.PROJECTION_ORTHOGONAL
    camera.size = 2.85
    camera.current = true
    camera.near = 0.05
    camera.far = 220.0
    world.add_child(camera)

    # Recreate the useful oblique inspection view first; keep game authority
    # strictly overhead in the separate second capture.
    camera.position = Vector3(3.8, 3.8, 5.0)
    if balanced_studio:
        camera.position = Vector3(3.8, 6.0, 5.0)
    camera.look_at(Vector3(0.0, 0.75, 0.0), Vector3.UP)
    await _settle_render()
    await _capture("01-godot-authored-materials-oblique.png")

    camera.position = Vector3(0.0, 5.0, 0.0)
    camera.rotation_degrees = Vector3(-90.0, 0.0, 0.0)
    camera.size = 2.65
    await _settle_render()
    await _capture("02-godot-authored-materials-overhead.png")

    var report := {
        "scope": "Static real Godot render of user-provided GLB; no gameplay outcome",
        "engine": Engine.get_version_info(),
        "renderer": RenderingServer.get_current_rendering_method(),
        "adapter": RenderingServer.get_video_adapter_name(),
        "source_sha256": FileAccess.get_sha256(source_path),
        "source_asset": source_path,
        "original_upload_sha256": FileAccess.get_sha256("res://d20_obsidian_gold.glb"),
        "mesh_count": material_receipts.size(),
        "source_materials_preserved": true,
        "cast_shadows": cast_shadows,
        "mesh_lod_threshold": root.mesh_lod_threshold,
        "studio_profile": "final" if final_studio else ("refined" if refined_studio else ("balanced" if balanced_studio else "baseline")),
        "clearcoat_restored_from_source_json": restore_authored_clearcoat,
        "materials": material_receipts,
        "captures": ["01-godot-authored-materials-oblique.png", "02-godot-authored-materials-overhead.png"],
        "phone_performance": "NOT_VERIFIED",
        "physical_rolls": "NOT_TESTED_BY_THIS_STATIC_ART_EXPERIMENT"
    }
    var file := FileAccess.open(output_folder + "/render-receipt.json", FileAccess.WRITE)
    file.store_string(JSON.stringify(report, "  "))
    file.close()
    print("D20_REVIEW_REAL_CAPTURE_DONE renderer=", report.renderer, " sha256=", report.source_sha256, " meshes=", report.mesh_count)
    quit(0)

func _inspect_materials(node: Node) -> void:
    if node is MeshInstance3D:
        var mesh_node := node as MeshInstance3D
        assert(mesh_node.material_override == null, "Original GLB material overwritten")
        assert(mesh_node.mesh.get_surface_count() == 1, "Unexpected mesh surfaces")
        var material := mesh_node.mesh.surface_get_material(0) as StandardMaterial3D
        assert(material != null, "Expected imported PBR material")
        assert(not material.emission_enabled, "Authored model must not emit light")
        material_receipts.append({
            "mesh": str(mesh_node.name), "material": material.resource_name,
            "metallic": material.metallic, "roughness": material.roughness,
            "clearcoat": material.clearcoat,
            "clearcoat_enabled": material.clearcoat_enabled,
            "clearcoat_texture": material.clearcoat_texture != null,
            "clearcoat_roughness": material.clearcoat_roughness,
            "albedo_texture": material.albedo_texture != null,
            "albedo_color": str(material.albedo_color),
            "roughness_texture": material.roughness_texture != null,
            "ao_enabled": material.ao_enabled,
            "normal_texture": material.normal_texture != null,
            "ao_texture": material.ao_texture != null,
            "normal_scale": material.normal_scale
        })
    for child in node.get_children():
        _inspect_materials(child)

func _read_authored_materials() -> void:
    var file := FileAccess.open(source_path, FileAccess.READ)
    assert(file != null)
    file.seek(12)
    var length := file.get_32()
    assert(file.get_32() == 0x4E4F534A, "GLB first chunk must be JSON")
    var document: Dictionary = JSON.parse_string(file.get_buffer(length).get_string_from_utf8())
    file.close()
    for raw in document.get("materials", []):
        authored_materials[str(raw.name)] = raw

func _restore_clearcoat(node: Node) -> void:
    # Godot 4.6.3's native import leaves this file's KHR coating disabled.
    # Restore only the exact authored scalar extension, keeping core PBR/maps.
    if node is MeshInstance3D:
        var mesh_node := node as MeshInstance3D
        var material := mesh_node.mesh.surface_get_material(0) as StandardMaterial3D
        assert(material != null and authored_materials.has(material.resource_name))
        var raw: Dictionary = authored_materials[material.resource_name]
        var coat: Dictionary = raw.get("extensions", {}).get("KHR_materials_clearcoat", {})
        assert(not coat.has("clearcoatTexture") and not coat.has("clearcoatRoughnessTexture"), "Texture coating needs a separate adapter")
        var factor := float(coat.get("clearcoatFactor", 0.0))
        material.clearcoat_enabled = factor > 0.0
        material.clearcoat = factor
        material.clearcoat_roughness = float(coat.get("clearcoatRoughnessFactor", 0.0))
    for child in node.get_children():
        _restore_clearcoat(child)

func _studio_panorama() -> ImageTexture:
    # A reproducible HDR studio reflection environment, never painted on the
    # dice and never a fake emission stripe. BRDF reads actual light directions.
    var image := Image.create(512, 256, false, Image.FORMAT_RGBF)
    var lights: Array[Dictionary] = [
        {"direction": Vector3(-0.70, 0.85, 0.80).normalized(), "color": Color(7.0, 6.3, 5.4), "width": 0.38, "height": 0.42},
        {"direction": Vector3(0.90, 0.50, -0.45).normalized(), "color": Color(2.3, 2.7, 3.5), "width": 0.18, "height": 0.55}
    ]
    if balanced_studio:
        lights = [
            {"direction": Vector3(-0.70, 0.85, 0.80).normalized(), "color": Color(3.2, 3.0, 2.7), "width": 0.60, "height": 0.65},
            {"direction": Vector3(0.90, 0.50, -0.45).normalized(), "color": Color(3.8, 3.9, 4.2), "width": 0.50, "height": 0.70}
        ]
    if refined_studio:
        lights = [
            {"direction": Vector3(-0.70, 0.85, 0.80).normalized(), "color": Color(1.8, 1.7, 1.6), "width": 0.60, "height": 0.65},
            {"direction": Vector3(0.90, 0.50, -0.45).normalized(), "color": Color(1.5, 1.6, 1.7), "width": 0.50, "height": 0.70}
        ]
    if final_studio:
        lights = [
            {"direction": Vector3(-0.70, 0.85, 0.80).normalized(), "color": Color(0.8, 0.76, 0.70), "width": 0.60, "height": 0.65},
            {"direction": Vector3(0.90, 0.50, -0.45).normalized(), "color": Color(0.65, 0.68, 0.72), "width": 0.50, "height": 0.70}
        ]
    for y in range(256):
        var theta := (float(y) + 0.5) / 256.0 * PI
        for x in range(512):
            var phi := (float(x) + 0.5) / 512.0 * TAU
            var direction := Vector3(sin(theta) * cos(phi), cos(theta), sin(theta) * sin(phi))
            var base := 0.026 + maxf(direction.y, 0.0) * 0.050
            if balanced_studio:
                base = 0.16 + maxf(direction.y, 0.0) * 0.15
            if refined_studio:
                base = 0.09 + maxf(direction.y, 0.0) * 0.10
            if final_studio:
                base = 0.07 + maxf(direction.y, 0.0) * 0.08
            var color := Color(base * 0.92, base, base * 1.03)
            for panel in lights:
                var axis: Vector3 = panel.direction
                var right := axis.cross(Vector3.UP).normalized()
                var up := right.cross(axis).normalized()
                var facing := direction.dot(axis)
                if facing > 0.0:
                    var px := absf(direction.dot(right) / facing)
                    var py := absf(direction.dot(up) / facing)
                    var feather := minf((float(panel.width) - px) / 0.045, (float(panel.height) - py) / 0.045)
                    color += (panel.color as Color) * clampf(feather, 0.0, 1.0)
            image.set_pixel(x, y, color)
    return ImageTexture.create_from_image(image)

func _settle_render() -> void:
    for frame in range(35):
        await process_frame
    await RenderingServer.frame_post_draw

func _capture(name: String) -> void:
    await RenderingServer.frame_post_draw
    var image := root.get_texture().get_image()
    assert(image != null and not image.is_empty(), "No real viewport image")
    var code := image.save_png(output_folder + "/" + name)
    assert(code == OK, "Could not write original Godot PNG")
    print("D20_REVIEW_ORIGINAL_PNG ", name, " ", image.get_size())
