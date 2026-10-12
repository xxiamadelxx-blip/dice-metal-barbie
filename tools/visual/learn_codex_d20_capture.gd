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
    assert(imported != null, "Exact source GLB not available")
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
    e.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
    e.ambient_light_energy = .72
    e.reflected_light_source = Environment.REFLECTION_SOURCE_SKY
    e.tonemap_mode = Environment.TONE_MAPPER_ACES
    var sky := Sky.new()
    # 256 radiance map allows free Mesa compatibility to finish on CPU.
    sky.radiance_size=Sky.RADIANCE_SIZE_256
    var smat := PanoramaSkyMaterial.new()
    smat.panorama = _build_studio_hdr()
    sky.sky_material = smat
    e.sky = sky
    envi.environment = e
    world.add_child(envi)
    for spec in [
        {"pos":Vector3(-3.4,4.8,-1.4),"energy":2.6,"color":Color(.82,.9,1)},
        {"pos":Vector3(3,3,.6),"energy":1.7,"color":Color(1,.83,.62)},
        {"pos":Vector3(0,5.5,-3.3),"energy":1.0,"color":Color(1,.95,.86)}
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
    assert(image.save_png(output+"/godot_compatibility.png")==OK)
    print("LEARNED_D20_GODOT_REAL_FRAME compatibility=",RenderingServer.get_current_rendering_method(),
        " gpu=",RenderingServer.get_video_adapter_name(),
        " size=",image.get_size(),
        " sha=",FileAccess.get_sha256(SOURCE))
    quit(0)

func _review_materials(node: Node) -> int:
    var count:=0
    if node is MeshInstance3D:
        var n:=node as MeshInstance3D
        count=1
        assert(n.material_override == null, "Source material overridden")
        var material:=n.mesh.surface_get_material(0) as BaseMaterial3D
        assert(material!=null)
        if "D20_Engraved" in str(n.name):
            assert(material.albedo_texture != null, "PBR albedo lost")
            assert(material.normal_texture != null, "Normal slot lost")
            assert(material.roughness_texture != null, "Roughness slot lost")
            material.clearcoat_enabled=true
            material.clearcoat=.20
            material.clearcoat_roughness=.09
            print("LEARNED_D20_MATERIAL_OBSIDIAN stone metallic=",material.metallic,
                " coat=",material.clearcoat," roughness_tex=",material.roughness_texture!=null,
                " ao=",material.ao_enabled)
        elif "Gold_" in str(n.name):
            material.clearcoat_enabled=true
            material.clearcoat=.06
            material.clearcoat_roughness=.25
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
