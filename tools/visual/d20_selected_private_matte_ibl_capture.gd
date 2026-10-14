extends SceneTree
# M5 real-engine proof with owner-private materials provided *locally*.
# Requires res://assets/hybrid_gold.glb and res://assets/studio.hdr,
# NEVER check licensed GLB, baked maps, or BlenderKit source into public git.
# Sample: godot --rendering-method mobile --script res://tools/visual/d20_selected_private_matte_ibl_capture.gd -- --bg=matte --yaw=128 --exposure=1.06 --fill=0.85
func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    var bg_mode := "matte"
    var fill_strength := 0.6
    var energy := 1.5
    var exposure := 1.0
    var sky_yaw := 70.0
    var sample := "hybrid_gold"
    for arg in OS.get_cmdline_user_args():
        if arg.begins_with("--bg="): bg_mode=arg.trim_prefix("--bg=")
        elif arg.begins_with("--fill="): fill_strength=float(arg.trim_prefix("--fill="))
        elif arg.begins_with("--key="): energy=float(arg.trim_prefix("--key="))
        elif arg.begins_with("--exposure="): exposure=float(arg.trim_prefix("--exposure="))
        elif arg.begins_with("--yaw="): sky_yaw=float(arg.trim_prefix("--yaw="))
        elif arg.begins_with("--sample="): sample=arg.trim_prefix("--sample=")
    assert(bg_mode in ["solid","sky","matte"])
    assert(sample in ["hybrid_gold","selected_polished_native_500k"])
    var source: PackedScene=load("res://assets/"+sample+".glb")
    assert(source != null, "The owner-private genuine BlenderKit PBR GLB was not provided")
    var viewport:=SubViewport.new()
    viewport.size=Vector2i(1024,896)
    viewport.render_target_update_mode=SubViewport.UPDATE_ALWAYS
    viewport.msaa_3d=Viewport.MSAA_4X
    root.add_child(viewport)
    var stage:=Node3D.new()
    viewport.add_child(stage)
    var die=source.instantiate()
    stage.add_child(die)
    var hdr=load("res://assets/studio.hdr")
    assert(hdr != null, "The original authorized private HDR was not provided")
    var pano:=PanoramaSkyMaterial.new()
    pano.panorama=hdr
    var sky:=Sky.new()
    sky.sky_material=pano
    var environment:=Environment.new()
    environment.background_mode=Environment.BG_COLOR if bg_mode=="solid" else Environment.BG_SKY
    environment.background_color=Color(.012,.015,.017)
    environment.sky=sky
    environment.sky_rotation=Vector3(0,deg_to_rad(sky_yaw),0)
    environment.ambient_light_source=Environment.AMBIENT_SOURCE_SKY
    environment.ambient_light_energy=.45
    environment.tonemap_exposure=exposure
    var world:=WorldEnvironment.new()
    world.environment=environment
    stage.add_child(world)
    var cam:=Camera3D.new()
    cam.projection=Camera3D.PROJECTION_ORTHOGONAL
    cam.size=3.25
    cam.position=Vector3(3.5,3.4,5.5)
    stage.add_child(cam)
    cam.look_at(Vector3.ZERO,Vector3.UP)
    cam.make_current()
    if bg_mode=="matte":
        # Mask visible studio light-card shapes from CAMERA, not from HDR IBL.
        # Setting BG_COLOR outright would throw away the desired reflections.
        var backing:=MeshInstance3D.new()
        var card:=QuadMesh.new()
        card.size=Vector2(80,80)
        backing.mesh=card
        backing.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
        var neutral:=StandardMaterial3D.new()
        neutral.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
        neutral.cull_mode=BaseMaterial3D.CULL_DISABLED
        neutral.albedo_color=Color(.012,.015,.017)
        backing.material_override=neutral
        backing.position=-cam.position.normalized()*6
        backing.look_at(cam.position,Vector3.UP)
        stage.add_child(backing)
    var key:=DirectionalLight3D.new()
    key.light_energy=energy
    key.rotation_degrees=Vector3(-37,28,-15)
    stage.add_child(key)
    var edge:=DirectionalLight3D.new()
    edge.light_energy=fill_strength
    edge.light_color=Color(1,.88,.70)
    edge.rotation_degrees=Vector3(50,-80,15)
    stage.add_child(edge)
    for i in range(8):
        await process_frame
        await RenderingServer.frame_post_draw
    var img=viewport.get_texture().get_image()
    assert(img!=null and img.get_size()==Vector2i(1024,896))
    var path="res://out/m5_studio_%s_bg%s_yaw%d_ex%.2f_fill%.2f.png"%[sample,bg_mode,int(sky_yaw),exposure,fill_strength]
    assert(img.save_png(path)==OK)
    var meshes=[]
    _collect(die,meshes)
    var total=0
    for m in meshes:
        for j in range(m.get_surface_count()):
            total+=int(m.surface_get_arrays(j)[Mesh.ARRAY_INDEX].size()/3)
    assert(meshes.size()==21 and total==500000, "Wrong original 500k mesh or gold count")
    print("PASS_REAL_M5_NATIVE_IBL_BACKDROP "+path+" 500000 21 "+RenderingServer.get_current_rendering_method()+" "+RenderingServer.get_video_adapter_name())
    quit(0)

func _collect(node:Node,meshes:Array)->void:
    if node is MeshInstance3D and node.mesh!=null: meshes.append(node.mesh)
    for child in node.get_children(): _collect(child,meshes)
