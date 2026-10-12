extends SceneTree
# Exact same newly created GLB used in Blender's delete/reimport round-trip.
const SOURCE := "res://src/assets/generated/learned_d20.glb"
const SIZE := Vector2i(1000,850)
var camera: Camera3D
var viewport: SubViewport
var world: Node3D
var output := "res://build/learned-d20"

func _initialize() -> void:
    call_deferred("_capture_main")

func _capture_main() -> void:
    # Three real engine A/B captures from a single identical exported GLB.
    var variant := "base"
    for arg in OS.get_cmdline_user_args():
        if arg == "--variant=ibl":
            variant = "ibl"
        elif arg == "--variant=ibl90":
            variant = "ibl90"
        elif arg == "--variant=aligned":
            variant = "aligned"
        elif arg == "--variant=aligned_boost":
            variant = "aligned_boost"
        elif arg == "--variant=narrow50":
            variant = "narrow50"
        elif arg == "--variant=narrow30":
            variant = "narrow30"
        elif arg == "--variant=narrow50_no_omni":
            variant = "narrow50_no_omni"
        elif arg.begins_with("--variant=micro_") or arg.begins_with("--variant=brdf_"):
            variant = arg.trim_prefix("--variant=")
        elif arg in ["--variant=lab_reference", "--variant=lab_clay",
                "--variant=lab_normals", "--variant=lab_normal_off",
                "--variant=lab_spec_off", "--variant=lab_direct",
                "--variant=lab_ibl", "--variant=lab_probe"]:
            variant = arg.trim_prefix("--variant=")
    DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output))
    viewport = SubViewport.new()
    viewport.name = "RealGLBCapture"
    viewport.size = SIZE
    viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
    viewport.msaa_3d = Viewport.MSAA_4X
    root.add_child(viewport)
    world = Node3D.new()
    viewport.add_child(world)
    var imported := load(SOURCE) as PackedScene
    if imported == null:
        push_error("FATAL: real D20 glTF not imported; ensure --editor --import --quit")
        quit(44)
        return
    var d20 := imported.instantiate() as Node3D
    assert(d20 != null)
    world.add_child(d20)
    var inspected := _review_materials(d20)
    assert(inspected >= 21, "Missing original independent gold glyph geometries")
    if variant.begins_with("brdf_") or variant.begins_with("micro_"):
        var material_count := _apply_brdf_to_stone(d20, variant)
        assert(material_count==2, "D20 must retain exactly two separate stone surface materials")
    var floor := MeshInstance3D.new()
    floor.name = "ComparisonFloor"
    var mesh := PlaneMesh.new()
    mesh.size = Vector2(200,200)
    floor.mesh = mesh
    floor.position = Vector3(0,-1.015,0)
    var matte := StandardMaterial3D.new()
    matte.albedo_color = Color(.085,.14,.12)
    matte.roughness = .92
    floor.material_override = matte
    world.add_child(floor)
    var envi := WorldEnvironment.new()
    var e := Environment.new()
    e.background_mode = Environment.BG_COLOR
    e.background_color = Color(.090,.14,.12)
    # Real diffuse fill is separate from reflection environment.
    # Black facets were nearly zero in the first imported Mobile frame.
    e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
    e.ambient_light_color = Color(.55,.60,.66)
    e.ambient_light_energy = 1.05
    e.reflected_light_source = Environment.REFLECTION_SOURCE_SKY
    e.tonemap_mode = Environment.TONE_MAPPER_ACES
    if variant.begins_with("brdf_") or variant.begins_with("micro_") or variant in ["ibl", "ibl90", "aligned", "aligned_boost", "narrow50", "narrow30", "narrow50_no_omni", "lab_reference", "lab_clay", "lab_normals", "lab_normal_off", "lab_spec_off", "lab_direct", "lab_ibl", "lab_probe"]:
        # Godot 4.6 documented sky ambient/AGX/exposure; follow Codex
        # real-runtime lessons instead of compensating black material via emission.
        e.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
        e.ambient_light_energy = .68
        e.ambient_light_sky_contribution = 1.0
        e.tonemap_mode = Environment.TONE_MAPPER_AGX
        e.tonemap_exposure = 1.52
        e.sky_rotation = Vector3(0, deg_to_rad(90.0) if variant == "ibl90" else 0.0, 0)
    var sky := Sky.new()
    # 256 radiance map allows free Mesa compatibility to finish on CPU.
    sky.radiance_size=Sky.RADIANCE_SIZE_256
    var smat := PanoramaSkyMaterial.new()
    var use_correct_axis_hdr := variant in ["aligned", "aligned_boost"]
    var panorama_path := "res://src/assets/generated/learned_studio_mobile_aligned.hdr" if use_correct_axis_hdr else "res://src/assets/generated/learned_studio.hdr"
    if variant in ["narrow50", "narrow30"]:
        panorama_path = "res://src/assets/generated/learned_studio_mobile_%s.hdr" % variant
    if variant == "narrow50_no_omni" or variant.begins_with("lab_") or variant.begins_with("brdf_") or variant.begins_with("micro_"):
        panorama_path = "res://src/assets/generated/learned_studio_mobile_narrow50.hdr"
    var same_studio_hdr := load(panorama_path) as Texture2D
    if same_studio_hdr == null:
        push_error("Shared Blender HDR studio environment did not import into Godot")
        quit(45)
        return
    smat.panorama = same_studio_hdr
    if variant == "aligned_boost":
        # Sky energy is increased, NOT stone emission or texture albedo.
        smat.energy_multiplier = 3.0
    print("D20_HDR_ALIGNMENT_VARIANT ",variant,
        " source=",panorama_path," panorama_energy=",smat.energy_multiplier)
    sky.sky_material = smat
    e.sky = sky
    envi.environment = e
    world.add_child(envi)
    for spec in [
        {"pos":Vector3(-3.4,4.8,-1.4),"energy":1.9,"color":Color(.82,.9,1)},
        {"pos":Vector3(3,3,.6),"energy":1.35,"color":Color(1,.83,.62)},
        {"pos":Vector3(0,5.5,-3.3),"energy":.85,"color":Color(1,.95,.86)}
    ]:
        var omni := OmniLight3D.new()
        omni.position = spec.pos
        omni.light_energy=0.0 if variant in ["narrow50_no_omni", "lab_ibl", "lab_probe"] else spec.energy
        omni.light_color=spec.color
        omni.omni_range=15
        omni.light_size=.8
        omni.shadow_enabled=true
        world.add_child(omni)
    camera=Camera3D.new()
    camera.projection=Camera3D.PROJECTION_ORTHOGONAL
    camera.size=3.0
    camera.position=Vector3(3.5,5.0,4.6)
    world.add_child(camera)
    camera.look_at(Vector3.ZERO,Vector3.UP)
    camera.make_current()
    if variant.begins_with("lab_"):
        _apply_layer_lab(d20, e, variant)
    if variant == "lab_probe":
        _install_reflection_probe(world, camera)
        # UPDATE_ONCE captures six sides over successive real frames.
        for i in range(12):
            await process_frame
    else:
        await create_timer(1.5).timeout
    await RenderingServer.frame_post_draw
    var image := viewport.get_texture().get_image()
    assert(image != null and image.get_size()==SIZE,"Source Godot frame wrong size")
    var screenshot_name := "godot_%s.png" % variant if variant != "base" else "godot_compatibility.png"
    assert(image.save_png(output+"/"+screenshot_name)==OK)
    print("LEARNED_D20_GODOT_REAL_FRAME variant=",variant," output=",screenshot_name,
        " renderer=",RenderingServer.get_current_rendering_method(),
        " gpu=",RenderingServer.get_video_adapter_name(),
        " size=",image.get_size(),
        " sha=",FileAccess.get_sha256(SOURCE))
    quit(0)

func _review_materials(node: Node) -> int:
    var count:=0
    if node is MeshInstance3D:
        var meshnode:=node as MeshInstance3D
        count=1
        assert(meshnode.material_override == null, "Imported GLB must not use a full object material override")
        var surface_count := meshnode.mesh.get_surface_count()
        assert(surface_count > 0)
        var saw_face := false
        var saw_edge := false
        for surface in range(surface_count):
            var material:=meshnode.mesh.surface_get_material(surface) as BaseMaterial3D
            assert(material != null, "Imported glTF surface lost PBR material")
            if "D20_Engraved" in str(meshnode.name):
                assert(material.albedo_texture != null, "Real PBR stone RGB lost")
                assert(material.normal_texture != null, "Stone normal lost")
                var is_edge := "EdgeSatin" in str(material.resource_name)
                if is_edge:
                    saw_edge = true
                    assert(material.roughness_texture == null, "Chamfer must have fixed satin roughness")
                    material.roughness = .31
                    material.clearcoat_enabled = true
                    material.clearcoat = .05
                    material.clearcoat_roughness = .30
                else:
                    saw_face = true
                    assert(material.roughness_texture != null, "Primary face must have its numeric ORM roughness")
                    material.clearcoat_enabled = true
                    material.clearcoat = .26
                    material.clearcoat_roughness = .09
                print("LEARNED_D20_STONE_SURFACE ",surface, " bevel=",is_edge,
                    " roughness=",material.roughness," coat=",material.clearcoat,
                    " material=",material.resource_name)
            elif "Gold_" in str(meshnode.name):
                material.clearcoat_enabled = true
                material.clearcoat = .06
                material.clearcoat_roughness = .25
        if "D20_Engraved" in str(meshnode.name):
            assert(surface_count >= 2 and saw_face and saw_edge,
                "A D20 needs BOTH independently preserved stone face and satin bevel materials")
            print("LEARNED_D20_SEPARATE_SURFACES_OK ",surface_count)
    for child in node.get_children():
        count+=_review_materials(child)
    return count


# Diagnostic visual passes (original real renderer, never painted/faked PNG).
# Each pass changes ONE component category while keeping mesh, pose and camera.
# Deterministic tangent-space lapping field for the 5x4 source triangle UV atlas.
# The source GLB, UV1, gold, bevel geometry and sky remain unchanged.
# Normal slope smoothly returns to zero at each tile edge, avoiding new seams.
func _make_face_micro_normal_atlas(slope: float) -> ImageTexture:
    var dim := 512
    var pic := Image.create(dim,dim,false,Image.FORMAT_RGB8)
    for y in range(dim):
        for x in range(dim):
            var u := fposmod((float(x)+.5)*5.0/float(dim),1.0)
            var v := fposmod((float(y)+.5)*4.0/float(dim),1.0)
            var edge_ramp := clampf(minf(minf(u,1.0-u),minf(v,1.0-v))*4.0,0.0,1.0)
            var tx := (u-.5)*2.0*slope*edge_ramp
            var ty := (v-.5)*2.0*slope*edge_ramp
            var tz := sqrt(maxf(0.0,1.0-tx*tx-ty*ty))
            pic.set_pixel(x,y,Color(.5+.5*tx,.5+.5*ty,.5+.5*tz,1.0))
    var tex := ImageTexture.create_from_image(pic)
    assert(tex!=null and tex.get_size()==Vector2i(dim,dim))
    print("D20_MICRONORMAL_AUTHORED slope=",slope," atlas=",tex.get_size(),
        " tile_uv=5x4, returns_to_flat_at_tile_boundaries=true")
    return tex

# Independent BRDF A/B. Render exactly the SAME scene/mesh/panorama.
# Make per-instance overrides instead of editing shared ArrayMesh or GLB.
# Never change gold, edge roughness or any face/vertex geometry.
func _apply_brdf_to_stone(d20: Node3D, variant: String) -> int:
    var total := 0
    var micro_map: Texture2D = null
    if variant in ["micro_006","micro_012","micro_020"]:
        var slope: float = {"micro_006":.06,"micro_012":.12,"micro_020":.20}[variant]
        micro_map = _make_face_micro_normal_atlas(slope)
    for child in d20.get_children():
        total += _override_d20_material_recursive(child, variant, micro_map)
    print("D20_BRDF_APPLIED mode=", variant, " stone_surfaces=", total)
    return total

func _override_d20_material_recursive(node: Node, variant: String, micro_map: Texture2D) -> int:
    var changed := 0
    if node is MeshInstance3D and "D20_Engraved" in str(node.name):
        var stone_mesh := node as MeshInstance3D
        assert(stone_mesh.mesh.get_surface_count()==2, "Fitted chamfer/face material counts changed")
        for idx in range(stone_mesh.mesh.get_surface_count()):
            var imported_mat := stone_mesh.mesh.surface_get_material(idx) as BaseMaterial3D
            assert(imported_mat != null and imported_mat.albedo_texture != null)
            var is_edge := "EdgeSatin" in str(imported_mat.resource_name)
            var custom := imported_mat.duplicate(true) as BaseMaterial3D
            assert(custom != null)
            if not is_edge:
                assert(custom.roughness_texture != null)
                if variant == "brdf_spec025" or variant.begins_with("micro_"):
                    custom.metallic_specular = 0.25
                    if micro_map != null:
                        custom.normal_enabled = true
                        custom.normal_texture = micro_map
                        custom.normal_scale = 1.0
                        assert(custom.normal_texture != null,"Micro-normal source lost")
                elif variant == "brdf_spec012":
                    custom.metallic_specular = 0.12
                elif variant == "brdf_coatoff":
                    custom.clearcoat_enabled = false
                elif variant == "brdf_rough024":
                    custom.roughness_texture = null
                    custom.roughness = .24
                elif variant == "brdf_rough010":
                    custom.roughness_texture = null
                    custom.roughness = .10
                elif variant == "brdf_coatsoft":
                    custom.clearcoat_roughness = .18
                elif variant == "brdf_ref" or variant == "brdf_spec050":
                    pass
                else:
                    push_error("Unknown BRDF variant: "+variant)
                    assert(false, "Unsupported BRDF variant")
                assert(custom.metallic == 0.0, "Obsidian was accidentally made metallic")
                print("D20_BRDF_FACE ",variant," F0knob=",custom.metallic_specular,
                      " rough=",custom.roughness," map=",custom.roughness_texture!=null,
                      " coat=",custom.clearcoat_enabled, " coat_R=",custom.clearcoat_roughness)
            else:
                assert(absf(custom.roughness - .31)<.02, "Physical chamfer style changed")
            # Override only imported D20 stone surface. Gold stays untouched.
            stone_mesh.set_surface_override_material(idx,custom)
            changed += 1
    for child in node.get_children():
        changed += _override_d20_material_recursive(child,variant,micro_map)
    return changed

func _apply_layer_lab(d20: Node3D, env: Environment, variant: String) -> void:
    print("D20_LAYER_LAB_MODE ", variant)
    if variant == "lab_direct":
        env.reflected_light_source = Environment.REFLECTION_SOURCE_DISABLED
        env.ambient_light_source = Environment.AMBIENT_SOURCE_DISABLED
    if variant == "lab_probe":
        # ReflectionProbe must carry the reflections; avoids double counting
        # the global studio panorama during this single-factor experiment.
        env.reflected_light_source = Environment.REFLECTION_SOURCE_DISABLED
    if variant in ["lab_clay", "lab_normals", "lab_normal_off", "lab_spec_off"]:
        var total := _apply_diagnostic_to_meshes(d20, variant)
        assert(total >= 21, "Diagnostic must affect all 20 gold inlays and original stone")
        print("D20_LAB_MATERIAL_INSTANCES ", total, " mode=", variant)

func _apply_diagnostic_to_meshes(node: Node, variant: String) -> int:
    var changed := 0
    if node is MeshInstance3D:
        var part := node as MeshInstance3D
        changed = 1
        if variant == "lab_clay":
            var clay := StandardMaterial3D.new()
            clay.albedo_color = Color(.53, .53, .53)
            clay.roughness = .89
            clay.metallic = 0.0
            clay.clearcoat_enabled = false
            clay.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL
            part.material_override = clay
        elif variant == "lab_normals":
            var shader := Shader.new()
            shader.code = "shader_type spatial;\nrender_mode unshaded, cull_back;\nvoid fragment() {\n  ALBEDO = normalize(NORMAL) * 0.5 + vec3(0.5);\n}\n"
            var m := ShaderMaterial.new()
            m.shader = shader
            part.material_override = m
        elif variant in ["lab_normal_off", "lab_spec_off"]:
            var imported_mesh := part.mesh as ArrayMesh
            assert(imported_mesh != null, "Need original ArrayMesh to edit its real surfaces")
            # Keep per-surface PBR properties, including the separate chamfer.
            for surface in range(imported_mesh.get_surface_count()):
                var original := imported_mesh.surface_get_material(surface) as BaseMaterial3D
                assert(original != null)
                var copy := original.duplicate(true) as BaseMaterial3D
                assert(copy != null)
                if variant == "lab_normal_off":
                    copy.normal_enabled = false
                else:
                    copy.roughness = 1.0
                    copy.roughness_texture = null
                    copy.clearcoat_enabled = false
                    copy.metallic = 0.0
                imported_mesh.surface_set_material(surface, copy)
    for child in node.get_children():
        changed += _apply_diagnostic_to_meshes(child, variant)
    return changed

func _install_reflection_probe(stage: Node3D, inspection: Camera3D) -> void:
    # A PS5-style studio-reflection TECHNIQUE, using the Godot Mobile API.
    # Fixture meshes are layer 2: visible to probe but NOT game camera.
    inspection.cull_mask = 1
    for spec in [
        {"at": Vector3(-2.4, 3.5, -2.6), "size": Vector2(1.0, 2.0),
         "color": Color(1.0, .85, .67), "power": 4.0},
        {"at": Vector3(3.2, 2.8, 1.0), "size": Vector2(.7, 2.2),
         "color": Color(.65, .82, 1.0), "power": 3.0}
    ]:
        var fixture := MeshInstance3D.new()
        fixture.name = "ReflectionOnlyPhysicalSoftbox"
        fixture.layers = 2
        fixture.position = spec.at
        var q := QuadMesh.new()
        q.size = spec.size
        fixture.mesh = q
        fixture.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
        stage.add_child(fixture)
        fixture.look_at(Vector3.ZERO, Vector3.UP)
        var material := StandardMaterial3D.new()
        material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
        material.cull_mode = BaseMaterial3D.CULL_DISABLED
        material.albedo_color = spec.color * spec.power
        fixture.material_override = material
    var probe := ReflectionProbe.new()
    probe.name = "OfflineStudioCaptureNoGeometrySelfReflection"
    probe.position = Vector3.ZERO
    probe.size = Vector3(5.0, 5.0, 5.0)
    probe.cull_mask = 2
    probe.reflection_mask = 1
    probe.intensity = 1.0
    probe.update_mode = ReflectionProbe.UPDATE_ONCE
    probe.box_projection = false
    probe.enable_shadows = false
    stage.add_child(probe)
    print("D20_LAB_REAL_REFLECTION_PROBE cull_mask=", probe.cull_mask,
         " reflection_mask=", probe.reflection_mask,
         " update_once=", probe.update_mode == ReflectionProbe.UPDATE_ONCE)

func _build_studio_hdr() -> ImageTexture:
    # Reflected long rectangular softbox shapes, not painted onto stone.
    var img:=Image.create(512,256,false,Image.FORMAT_RGBF)
    var sources=[
        {"dir":Vector3(-.70,.85,.80).normalized(),"color":Color(2.7,3.0,3.3),"w":.52,"h":.68},
        {"dir":Vector3(.9,.5,-.45).normalized(),"color":Color(2.6,2.3,1.7),"w":.24,"h":.72},
        {"dir":Vector3(.1,.95,-.2).normalized(),"color":Color(1.2,1.1,1.0),"w":.40,"h":.30},
    ]
    for y in range(256):
        var theta:float=(float(y)+.5)/256.0*PI
        for x in range(512):
            var phi:float=(float(x)+.5)/512.0*TAU
            var d:=Vector3(sin(theta)*cos(phi),cos(theta),sin(theta)*sin(phi))
            var base:float=.13+maxf(d.y,0)*.10
            var value:=Color(base*.91,base,base*1.06)
            for s in sources:
                var normal:Vector3=s.dir
                var right:=normal.cross(Vector3.UP).normalized()
                var up:=right.cross(normal).normalized()
                var facing:float=d.dot(normal)
                if facing>0:
                    var rx:float=abs(d.dot(right)/facing)
                    var ry:float=abs(d.dot(up)/facing)
                    var fade:float=minf((float(s.w)-rx)/.07,(float(s.h)-ry)/.07)
                    value+=(s.color as Color)*clampf(fade,0,1)
            img.set_pixel(x,y,value)
    return ImageTexture.create_from_image(img)
