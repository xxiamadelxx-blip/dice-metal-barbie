extends SceneTree
## Real isolated native Godot 4.6.3 preview, created after recovering the genuine
## user-selected BlenderKit Procedural Obsidian source from private ChatGPT Library.
## IMPORTANT: This script contains NO licensed material data.
## In PRIVATE working directory only, create project.godot and provide:
##     res://d20_selected.glb  (repaired true 500k source with selected material)
##     res://studio.hdr        (original selected HDR, not a fabricated texture)
## Run:
## godot --display-driver x11 --rendering-method gl_compatibility \
##   --path /PRIVATE/PROJECT --script res://capture_real_selected.gd -- --sky-yaw=35
## This is a diagnostic native renderer, NOT full premium art approval or Android FPS.

func _initialize() -> void:
    call_deferred("_capture")

func _capture() -> void:
    var sky_yaw := 0.0
    for a in OS.get_cmdline_user_args():
        if a.begins_with("--sky-yaw="):
            sky_yaw = float(a.trim_prefix("--sky-yaw="))
    var file := "res://godot_selected_500k_HDR_yaw%03d.png" % int(sky_yaw)
    var vp := SubViewport.new()
    vp.size = Vector2i(1000, 850)
    vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
    vp.msaa_3d = Viewport.MSAA_4X
    root.add_child(vp)
    var scene3d := Node3D.new()
    vp.add_child(scene3d)

    var packed := load("res://d20_selected.glb") as PackedScene
    assert(packed != null)
    var die := packed.instantiate()
    scene3d.add_child(die)
    var meshes := 0
    var triangles := 0
    var gold := 0
    for node in die.find_children("*", "MeshInstance3D", true, false):
        if node is MeshInstance3D:
            meshes += 1
            if node.name.begins_with("Gold_"):
                gold += 1
            var mesh: Mesh = node.mesh
            for s in range(mesh.get_surface_count()):
                var arr := mesh.surface_get_arrays(s)
                var indices: PackedInt32Array = arr[Mesh.ARRAY_INDEX]
                triangles += int(indices.size() / 3) if indices.size() > 0 else int(arr[Mesh.ARRAY_VERTEX].size() / 3)
    assert(meshes == 21 and triangles == 500000 and gold == 20)
    print("M5_PRIVATE_SELECTED_GODOT_VERIFIED meshes=",meshes, " triangles=",triangles," gold=",gold)

    var camera := Camera3D.new()
    camera.projection = Camera3D.PROJECTION_ORTHOGONAL
    camera.size = 3.25
    camera.position = Vector3(2.9, 3.7, 4.7)
    scene3d.add_child(camera)
    camera.look_at(Vector3.ZERO, Vector3.UP)
    camera.make_current()

    var env := Environment.new()
    env.background_mode = Environment.BG_COLOR
    env.background_color = Color(0.021,0.033,0.033)
    env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
    env.ambient_light_color = Color(0.53,0.62,0.65)
    env.ambient_light_energy = 0.45
    env.reflected_light_source = Environment.REFLECTION_SOURCE_BG
    var panorama := load("res://studio.hdr") as Texture2D
    assert(panorama != null)
    var sky_mat := PanoramaSkyMaterial.new()
    sky_mat.panorama = panorama
    var sky := Sky.new()
    sky.sky_material = sky_mat
    env.sky = sky
    env.sky_rotation = Vector3(0, deg_to_rad(sky_yaw), 0)
    env.background_mode = Environment.BG_SKY
    env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
    env.reflected_light_source = Environment.REFLECTION_SOURCE_BG
    var environment := WorldEnvironment.new()
    environment.environment = env
    scene3d.add_child(environment)

    # Solid studio backdrop hides bright environment outside D20 silhouette,
    # while retaining actual saved HDR image-based lighting on the D20.
    var backdrop := MeshInstance3D.new()
    var quad := QuadMesh.new()
    quad.size = Vector2(200,200)
    backdrop.mesh = quad
    var matte := StandardMaterial3D.new()
    matte.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
    matte.cull_mode = BaseMaterial3D.CULL_DISABLED
    matte.albedo_color = Color(0.03,0.043,0.044)
    backdrop.material_override = matte
    scene3d.add_child(backdrop)
    backdrop.position = -camera.position.normalized() * 5.0
    backdrop.look_at(camera.position, Vector3.UP)
    var key := DirectionalLight3D.new()
    key.light_energy = 1.1
    key.rotation_degrees = Vector3(-44,28,-22)
    scene3d.add_child(key)

    for i in range(8):
        await process_frame
        await RenderingServer.frame_post_draw
    var img := vp.get_texture().get_image()
    var status := img.save_png(file)
    print("M5_PRIVATE_SELECTED_ACTUAL_GODOT_FRAME",file,"result",status,
      "size",img.get_size(),"renderer",RenderingServer.get_current_rendering_method(),
      "gpu",RenderingServer.get_video_adapter_name())
    quit(0 if status == OK else 2)
