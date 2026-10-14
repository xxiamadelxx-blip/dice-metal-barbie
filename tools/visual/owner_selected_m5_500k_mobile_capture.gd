extends SceneTree
const WIDTH := 1000
const HEIGHT := 850
const SOURCE := "res://assets/d20_selected_original_500k.glb"
const PANORAMA := "res://assets/aligned_original_selected_studio.hdr"
var variant := "baseline"
var yaw_degrees: float = 0.0

func _initialize() -> void:
    call_deferred("run_capture")

func apply_variant(n: Node, variant_name: String) -> Dictionary:
    var stat := {"mesh_count":0,"stone_tris":0,"gold_tris":0,"gold_count":0,"stone_material_names":[],"gold_original_albedo":null}
    _visit(n,variant_name,stat)
    return stat

func _visit(n: Node, v: String, stat: Dictionary) -> void:
    if n is MeshInstance3D:
        var m := n as MeshInstance3D
        assert(m.mesh != null)
        stat.mesh_count += 1
        for s in range(m.mesh.get_surface_count()):
            var mat := m.mesh.surface_get_material(s) as BaseMaterial3D
            assert(mat != null)
            var surf_count: int = m.mesh.surface_get_arrays(s)[Mesh.ARRAY_INDEX].size()
            assert(surf_count % 3 == 0)
            if str(n.name).begins_with("Gold_"):
                stat.gold_tris += surf_count/3
                if stat.gold_original_albedo == null:
                    stat.gold_original_albedo = str(mat.albedo_color)
                if v in ["gold_warm", "balanced", "quiet", "probe", "probe_polished", "probe_five", "probe_refined"]:
                    var improved := mat.duplicate(true) as BaseMaterial3D
                    improved.albedo_color = Color(.92,.64,.27)
                    improved.metallic = .55
                    improved.roughness = .29
                    improved.clearcoat_enabled = true
                    improved.clearcoat = .08
                    improved.clearcoat_roughness = .22
                    m.set_surface_override_material(s,improved)
            elif str(n.name).begins_with("D20_Engraved"):
                stat.stone_tris += surf_count/3
                stat.stone_material_names.append(mat.resource_name)
                assert(mat.albedo_texture != null, "Selected source black albedo missing")
                # Keep imported, source-baked tangent normal map and source PBR untouched.
                if "EdgeSatin" not in str(mat.resource_name):
                    assert(mat.normal_texture != null,"Real source 2k bake lost")
                    if v == "probe_polished":
                        var polished:=mat.duplicate(true) as BaseMaterial3D
                        polished.clearcoat_enabled=true
                        polished.clearcoat=.45
                        polished.clearcoat_roughness=.075
                        polished.metallic_specular=.65
                        # The licensed source's texture, color, original base roughness,
                        # tangent 2K normal and all geometry remain unmodified.
                        assert(polished.albedo_texture==mat.albedo_texture)
                        assert(polished.normal_texture==mat.normal_texture)
                        m.set_surface_override_material(s,polished)
            else:
                push_error("Unexpected imported mesh "+str(n.name))
        if str(n.name).begins_with("Gold_"):
            stat.gold_count += 1
    for ch in n.get_children():
        _visit(ch,v,stat)

func run_capture() -> void:
    for arg in OS.get_cmdline_user_args():
        if arg.begins_with("--variant="):
            variant = arg.trim_prefix("--variant=")
        if arg.begins_with("--yaw="):
            yaw_degrees=float(arg.trim_prefix("--yaw="))
    assert(variant in ["baseline","gold_warm","balanced","quiet","probe","probe_polished","probe_five","probe_refined"])
    DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://out"))
    var viewport := SubViewport.new()
    viewport.name="RealGodotSelectedBlendkit500k"
    viewport.size=Vector2i(WIDTH,HEIGHT)
    viewport.render_target_update_mode=SubViewport.UPDATE_ALWAYS
    viewport.msaa_3d = Viewport.MSAA_4X
    root.add_child(viewport)
    var world := Node3D.new()
    world.name="Stage"
    viewport.add_child(world)
    var packed := load(SOURCE) as PackedScene
    assert(packed != null,"Original 500k glTF failed real Godot import")
    var die := packed.instantiate()
    world.add_child(die)
    var stats := apply_variant(die, variant)
    assert(stats.mesh_count==21 and stats.gold_count==20)
    assert(stats.stone_tris+stats.gold_tris==500000)

    var floor := MeshInstance3D.new()
    floor.mesh=PlaneMesh.new()
    floor.mesh.size=Vector2(120,120)
    floor.position=Vector3(0,-1.11,0)
    var floor_mat:=StandardMaterial3D.new()
    floor_mat.albedo_color=Color(.045,.062,.060)
    floor_mat.metallic=0.0
    floor_mat.roughness=.95
    floor.material_override=floor_mat
    world.add_child(floor)

    var env_node:=WorldEnvironment.new()
    var env:=Environment.new()
    env.background_mode=Environment.BG_COLOR
    env.background_color=Color(.035,.051,.047)
    env.ambient_light_source=Environment.AMBIENT_SOURCE_SKY
    env.ambient_light_energy=.8 if variant=="baseline" else (.65 if variant=="quiet" else .95)
    env.ambient_light_sky_contribution=1.0
    env.reflected_light_source=Environment.REFLECTION_SOURCE_SKY
    env.sky_rotation=Vector3(0.0,deg_to_rad(yaw_degrees),0.0)
    env.tonemap_mode=Environment.TONE_MAPPER_AGX
    env.tonemap_exposure=1.52 if variant=="baseline" else (1.70 if variant=="quiet" else 1.90)
    # IMPORTANT: original high-dynamic-range studio can illuminate the die,
    # but its white fixture polygons must not appear as visible background.
    var sky:=Sky.new()
    sky.radiance_size=Sky.RADIANCE_SIZE_256
    var smat:=PanoramaSkyMaterial.new()
    var hdr:=load(PANORAMA) as Texture2D
    assert(hdr != null)
    smat.panorama=hdr
    smat.energy_multiplier=.9 if variant=="baseline" else (.62 if variant=="quiet" else .82)
    sky.sky_material=smat
    env.sky=sky
    env_node.environment=env
    world.add_child(env_node)
    if variant in ["probe", "probe_polished", "probe_five", "probe_refined"]:
        # Reflection-only large softboxes: visible to reflection probe, hidden
        # from camera. This simulates photographic studio cards without
        # drawing white rectangles in the final D20 frame.
        for setup in [
            {"pos":Vector3(-3.8,3.5,3.0),"size":Vector2(2.0,4.0),
             "tint":Color(.82,.91,1.0),"lux":3.2},
            {"pos":Vector3(3.8,2.8,1.0),"size":Vector2(1.2,4.3),
             "tint":Color(1.0,.78,.48),"lux":2.4},
            {"pos":Vector3(0.0,5.0,-1.8),"size":Vector2(4.0,1.4),
             "tint":Color(.95,.96,1.0),"lux":2.0},
            # Target physically predicted specular reflection directions
            # from the original GLB gold-20 and gold-17 face normals, not
            # a shader-painted visual highlight.
            {"pos":Vector3(-3.1,2.9,-4.2),"size":Vector2(1.6,2.6),
             "tint":Color(.83,.91,1.0),"lux":2.7},
            {"pos":Vector3(3.3,-0.8,4.8),"size":Vector2(2.1,2.3),
             "tint":Color(1.0,.87,.67),"lux":2.3},
        ]:
            if variant not in ["probe_five","probe_refined"] and setup.pos in [Vector3(-3.1,2.9,-4.2),Vector3(3.3,-0.8,4.8)]:
                continue
            var fixture:=MeshInstance3D.new()
            fixture.name="StudioReflectorNotInCamera"
            fixture.layers=2
            fixture.position=setup.pos
            var quad:=QuadMesh.new()
            var narrow_card: bool = variant=="probe_refined" and setup.pos in [Vector3(-3.1,2.9,-4.2),Vector3(3.3,-0.8,4.8)]
            quad.size=setup.size*.48 if narrow_card else setup.size
            fixture.mesh=quad
            fixture.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
            world.add_child(fixture)
            fixture.look_at(Vector3.ZERO,Vector3.UP)
            var glowing:=StandardMaterial3D.new()
            glowing.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
            glowing.cull_mode=BaseMaterial3D.CULL_DISABLED
            glowing.albedo_color=setup.tint
            glowing.emission_enabled=true
            glowing.emission=setup.tint
            glowing.emission_energy_multiplier=setup.lux*(.80 if variant=="probe_refined" else 1.0)
            fixture.material_override=glowing
        var capture_probe:=ReflectionProbe.new()
        capture_probe.name="CameraHiddenPhysicalStudioLightCards"
        capture_probe.position=Vector3.ZERO
        capture_probe.size=Vector3(8.0,8.0,8.0)
        capture_probe.cull_mask=2
        capture_probe.reflection_mask=1
        capture_probe.intensity=1.50 if variant=="probe_refined" else 1.8
        capture_probe.update_mode=ReflectionProbe.UPDATE_ONCE
        capture_probe.enable_shadows=false
        world.add_child(capture_probe)
        env.reflected_light_source=Environment.REFLECTION_SOURCE_DISABLED
    for ls in [
        {"pos":Vector3(-3.4,4.8,-1.4),"energy":1.9,"color":Color(.83,.9,1.0)},
        {"pos":Vector3(3.0,3.0,.6),"energy":1.5,"color":Color(1.0,.88,.7)},
        {"pos":Vector3(0,5.5,-3.3),"energy":1.0,"color":Color(1.0,.97,.9)},
    ]:
        var lamp:=OmniLight3D.new()
        lamp.position=ls.pos
        lamp.light_energy=ls.energy if variant=="baseline" else (ls.energy*1.25 if variant=="quiet" else ls.energy*1.4)
        lamp.light_color=ls.color
        lamp.omni_range=16
        lamp.light_size=.8
        lamp.shadow_enabled=true
        world.add_child(lamp)
    var cam:=Camera3D.new()
    cam.projection=Camera3D.PROJECTION_ORTHOGONAL
    cam.size=3.0
    cam.position=Vector3(3.5,5.0,4.6)
    world.add_child(cam)
    cam.look_at(Vector3.ZERO,Vector3.UP)
    cam.make_current()
    if variant in ["probe", "probe_polished", "probe_five", "probe_refined"]:
        cam.cull_mask=1
    for frame in range(35 if variant in ["probe", "probe_polished", "probe_five", "probe_refined"] else 14):
        await process_frame
    await RenderingServer.frame_post_draw
    var screenshot:=viewport.get_texture().get_image()
    assert(screenshot!=null and screenshot.get_size()==Vector2i(WIDTH,HEIGHT))
    var target="res://out/godot_%s_yaw%03d_real_source.png"%[variant,int(yaw_degrees+360)%360]
    assert(screenshot.save_png(target)==OK)
    print("M5_REAL_GODOT_SOURCE_CAPTURE variant=",variant," yaw=",yaw_degrees,
      " renderer=",RenderingServer.get_current_rendering_method(),
      " gpu=",RenderingServer.get_video_adapter_name(),
      " mesh_count=",stats.mesh_count," stone_tris=",stats.stone_tris,
      " gold_tris=",stats.gold_tris," gold_count=",stats.gold_count,
      " shader_mats=",stats.stone_material_names," output=",target)
    quit(0)