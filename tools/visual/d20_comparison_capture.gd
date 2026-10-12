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
	if variant != "source" and variant != "production":
		push_error("Invalid render variant")
		quit(3)
		return
	root.size = Vector2i(768, 768)
	var stage := Node3D.new()
	stage.name = "IsolatedGLBComparison"
	root.add_child(stage)
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
	if variant == "production":
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
	var rendered := root.get_texture().get_image()
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
