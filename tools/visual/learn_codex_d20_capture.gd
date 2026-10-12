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
    if variant in ["ibl", "ibl90", "aligned", "aligned_boost", "narrow50", "narrow30"]:
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
        omni.light_energy=spec.energy
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
    # The compatibility software renderer is slow at 1000x850.
    # Wait a short wall-clock settle and a single *real* completed frame.
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
