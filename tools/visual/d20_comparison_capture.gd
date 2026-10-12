extends SceneTree
## Original Godot screenshot of EXACT SAME freshly-exported D20 GLB used in Blender.
## Not an artist drawing, not a staged gameplay result or phone performance test.
const Premium = preload("res://src/visual/premium_finish.gd")
const GLB_PATH = "res://src/assets/generated/d20_boolean_engraved.glb"

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var variant := "source"
	for arg in OS.get_cmdline_user_args():
		if arg == "--variant=production":
			variant = "production"
		elif arg == "--variant=source":
			variant = "source"
		elif arg == "--variant=studio":
			variant = "studio"
		elif arg == "--variant=studio_production":
			variant = "studio_production"
	if variant not in ["source","production","studio","studio_production"]:
		push_error("Invalid render variant")
		quit(3)
		return
	root.size = Vector2i(768, 768)
	# Dedicated real GPU render target: main project viewport is 720x1280.
	# A Window.size change alone does NOT resize its content viewport.
	var capture_viewport := SubViewport.new()
	capture_viewport.name = "RealGodot768SquareSource"
	capture_viewport.size = Vector2i(768, 768)
	capture_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(capture_viewport)
	var stage := Node3D.new()
	stage.name = "IsolatedGLBComparison"
	capture_viewport.add_child(stage)
	var packed: PackedScene = load(GLB_PATH)
	if packed == null:
		push_error("Missing exact source GLB: " + GLB_PATH)
		quit(4)
		return
	var art := packed.instantiate() as Node3D
	if art == null:
		push_error("Source glTF did not instantiate")
		quit(5)
		return
	art.name = "ExactSourceD20"
	stage.add_child(art)
	if variant in ["production","studio_production"]:
		Premium._finish_glb_node(art)
	var floor_mesh := MeshInstance3D.new()
	var mesh := PlaneMesh.new()
	mesh.size = Vector2(200, 200)
	floor_mesh.mesh = mesh
	floor_mesh.position = Vector3(0, -0.97, 0)
	floor_mesh.name = "ComparisonFloor_NonColliding"
	var floor_material := StandardMaterial3D.new()
	floor_material.albedo_color = Color(0.080, 0.162, 0.137)
	floor_material.roughness = 0.94
	floor_material.metallic = 0.0
	floor_mesh.material_override = floor_material
	stage.add_child(floor_mesh)
	var env_node := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.10, 0.13, 0.14)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.10, 0.13, 0.14)
	env.ambient_light_energy = 0.6
	# Single controlled change: only studio variants enable an authored
	# reflective sky. Source and production variants preserve the old scene.
	# This sky never becomes the game's background: the black/green table
	# and fixed camera retain their approved gameplay constraints.
	if variant in ["studio", "studio_production"]:
		var sky := Sky.new()
		sky.radiance_size = Sky.RADIANCE_SIZE_256
		var sky_material := ShaderMaterial.new()
		sky_material.shader = load("res://tools/visual/studio_softboxes.gdshader")
		sky.sky_material = sky_material
		env.sky = sky
		env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
		env.reflected_light_source = Environment.REFLECTION_SOURCE_SKY
		env.ambient_light_energy = 0.72
		print("D20_STUDIO_REFLECTION_SOURCE: SKY, authored procedural softboxes, not Cycles")
	env_node.environment = env
	stage.add_child(env_node)
	# Coordinate mapping Blender Z-up -> Godot Y-up: (x,y,z) -> (x,z,-y).
	# OmniLights are a visible limitation: Godot gl_compatibility has no
	# physical Cycles disk-shaped area sources; record, do not conceal, mismatch.
	for spec in [
		{"pos": Vector3(-3,4,2), "color": Color(1.0,0.77,0.56), "energy": 2.8},
		{"pos": Vector3(3,1,-2), "color": Color(0.52,0.72,1.0), "energy": 2.2},
	]:
		var light := OmniLight3D.new()
		light.position = spec["pos"]
		light.light_color = spec["color"]
		light.light_energy = spec["energy"]
		light.omni_range = 12.0
		light.shadow_enabled = true
		stage.add_child(light)
	var camera := Camera3D.new()
	camera.name = "MatchBlenderCamera"
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 3.15
	camera.position = Vector3(2.8, 2.5, 3.2)
	stage.add_child(camera)
	camera.look_at(Vector3.ZERO, Vector3.UP)
	camera.make_current()
	await create_timer(1.5).timeout
	await RenderingServer.frame_post_draw
	var rendered := capture_viewport.get_texture().get_image()
	if rendered != null:
		print("REAL_CAPTURE_DIMENSIONS ", rendered.get_size())
	if rendered == null or rendered.is_empty() or rendered.get_width() != 768 or rendered.get_height() != 768:
		push_error("No valid Godot 768x768 rendered frame")
		quit(6)
		return
	var output := "res://build/d20-compare/godot_%s.png" % variant
	if rendered.save_png(output) != OK:
		push_error("Godot source screenshot saving failed")
		quit(7)
		return
	print("PASS ACTUAL GODOT FRAME: " + output + " variant=" + variant + " renderer=" + str(ProjectSettings.get_setting("rendering/renderer/rendering_method")))
	quit()
