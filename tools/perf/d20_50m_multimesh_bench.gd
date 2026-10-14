extends SceneTree
# M5 research only: 0.5M -> 50M exactly, 100 stages; 50k/instance on the GPU.
# 1000 instanced D20s is NOT one 50-million triangle GLB or a Nord 3 result.
const T := 50000
const STEP := 500000
const GRID := 50
const VIEW := Vector2i(640, 640)
var first := 1
var last := 25
var mm: MultiMesh
var vp: SubViewport
var output: FileAccess

func _initialize() -> void:
    call_deferred("_run")

func _record(data: Dictionary) -> void:
    output.store_line(JSON.stringify(data))
    output.flush()
    print("D20_PERF_REAL_STAGE ", JSON.stringify(data))

func _point(a: Vector3, b: Vector3, c: Vector3, u: float, v: float) -> Vector3:
    return a + (b-a)*u + (c-a)*v

func _add_triangle(p: PackedVector3Array, n: PackedVector3Array, a: Vector3, b: Vector3, c: Vector3, face_normal: Vector3) -> void:
    p.append(a)
    p.append(b)
    p.append(c)
    n.append(face_normal)
    n.append(face_normal)
    n.append(face_normal)

func _mesh() -> ArrayMesh:
    var phi := (1.0+sqrt(5.0))/2.0
    var v := [Vector3(-1,phi,0),Vector3(1,phi,0),Vector3(-1,-phi,0),Vector3(1,-phi,0),
        Vector3(0,-1,phi),Vector3(0,1,phi),Vector3(0,-1,-phi),Vector3(0,1,-phi),
        Vector3(phi,0,-1),Vector3(phi,0,1),Vector3(-phi,0,-1),Vector3(-phi,0,1)]
    var faces := [[0,11,5],[0,5,1],[0,1,7],[0,7,10],[0,10,11],
        [1,5,9],[5,11,4],[11,10,2],[10,7,6],[7,1,8],
        [3,9,4],[3,4,2],[3,2,6],[3,6,8],[3,8,9],
        [4,9,5],[2,4,11],[6,2,10],[8,6,7],[9,8,1]]
    var p := PackedVector3Array()
    var n := PackedVector3Array()
    for face in faces:
        var a: Vector3 = v[face[0]].normalized()
        var b: Vector3 = v[face[1]].normalized()
        var c: Vector3 = v[face[2]].normalized()
        var normal := (b-a).cross(c-a).normalized()
        if normal.dot(a+b+c)<0.0:
            var old := b
            b = c
            c = old
            normal = -normal
        for row in range(GRID):
            for col in range(GRID-row):
                var u := float(col)/GRID
                var w := float(row)/GRID
                var d := 1.0/GRID
                var p0 := _point(a,b,c,u,w)
                var p1 := _point(a,b,c,u+d,w)
                var p2 := _point(a,b,c,u,w+d)
                _add_triangle(p,n,p0,p1,p2,normal)
                if col+row+1<GRID:
                    var p3 := _point(a,b,c,u+d,w+d)
                    _add_triangle(p,n,p1,p3,p2,normal)
    assert(p.size()==T*3)
    var arrays := []
    arrays.resize(Mesh.ARRAY_MAX)
    arrays[Mesh.ARRAY_VERTEX]=p
    arrays[Mesh.ARRAY_NORMAL]=n
    var m := ArrayMesh.new()
    m.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
    assert(m.surface_get_array_len(0)==T*3)
    var mat := StandardMaterial3D.new()
    mat.albedo_color=Color(.015,.017,.020)
    mat.roughness=.17
    mat.metallic=0.0
    mat.clearcoat_enabled=true
    mat.clearcoat=.25
    mat.clearcoat_roughness=.09
    m.surface_set_material(0,mat)
    return m

func _arrange(instances: int) -> void:
    var cols := int(ceil(sqrt(float(instances))))
    var pitch := 26.0/float(cols)
    var basis := Basis().scaled(Vector3.ONE*(pitch*.34))
    for i in range(instances):
        var column := i%cols
        var row := int(i/cols)
        var tr := Vector3(-13.0+(column+.5)*pitch,0,-13.0+(row+.5)*pitch)
        mm.set_instance_transform(i,Transform3D(basis,tr))
    mm.visible_instance_count=instances

func _run() -> void:
    for arg in OS.get_cmdline_user_args():
        if arg.begins_with("--from="):
            first=int(arg.trim_prefix("--from="))
        elif arg.begins_with("--to="):
            last=int(arg.trim_prefix("--to="))
    assert(first>=1 and last<=100 and last>=first)
    DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://build/d20-50m"))
    output=FileAccess.open("res://build/d20-50m/stages_%03d_%03d.jsonl"%[first,last],FileAccess.WRITE)
    assert(output!=null)
    var started := Time.get_ticks_msec()
    var mesh := _mesh()
    var build_ms := Time.get_ticks_msec()-started
    vp=SubViewport.new()
    vp.size=VIEW
    vp.msaa_3d=Viewport.MSAA_DISABLED
    vp.render_target_update_mode=SubViewport.UPDATE_ALWAYS
    root.add_child(vp)
    var world := Node3D.new()
    vp.add_child(world)
    mm=MultiMesh.new()
    mm.transform_format=MultiMesh.TRANSFORM_3D
    mm.mesh=mesh
    mm.instance_count=last*10
    mm.visible_instance_count=0
    mm.custom_aabb=AABB(Vector3(-16,-2,-16),Vector3(32,4,32))
    var batch := MultiMeshInstance3D.new()
    batch.multimesh=mm
    world.add_child(batch)
    var cam := Camera3D.new()
    cam.projection=Camera3D.PROJECTION_ORTHOGONAL
    cam.size=30
    cam.position=Vector3(0,39,0)
    world.add_child(cam)
    cam.look_at(Vector3.ZERO,Vector3(0,0,-1))
    cam.make_current()
    var sun := DirectionalLight3D.new()
    sun.rotation_degrees=Vector3(-35,40,0)
    sun.light_energy=2.5
    sun.shadow_enabled=false
    world.add_child(sun)
    var env := WorldEnvironment.new()
    var e := Environment.new()
    e.background_mode=Environment.BG_COLOR
    e.background_color=Color(.015,.018,.02)
    e.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR
    e.ambient_light_color=Color(.8,.8,.86)
    e.ambient_light_energy=.8
    env.environment=e
    world.add_child(env)
    _record({"kind":"header","first":first,"last":last,"mesh_triangles":T,
      "increments":STEP,"texture":"NO / shared dielectric test material",
      "benchmark":"total_gpu_instanced_submitted_triangles_NOT_single_mesh",
      "viewport":[VIEW.x,VIEW.y],"msaa":false,"physics":false,
      "renderer":RenderingServer.get_current_rendering_method(),
      "gpu":RenderingServer.get_video_adapter_name(),"mesh_generation_ms":build_ms})
    # Prime actual shaders and same renderer path BEFORE timing, so compilation is not FPS.
    _arrange(first*10)
    var warmup_ms := []
    for warm in range(4):
        var a := Time.get_ticks_usec()
        await process_frame
        await RenderingServer.frame_post_draw
        warmup_ms.append(float(Time.get_ticks_usec()-a)/1000.0)
    _record({"kind":"warmup","first":first,"samples_ms":warmup_ms,
      "excluded_from_per_stage_timing":true})
    var abort_reason := ""
    for step in range(first,last+1):
        var total := step*STEP
        if abort_reason!="":
            _record({"step":step,"target_tris":total,"status":"NOT_RUN","reason":abort_reason})
            continue
        var count := step*10
        var setup := Time.get_ticks_msec()
        _arrange(count)
        var setup_ms := Time.get_ticks_msec()-setup
        var frames := []
        for sample in range(2):
            var start := Time.get_ticks_usec()
            await process_frame
            await RenderingServer.frame_post_draw
            var frame_ms := float(Time.get_ticks_usec()-start)/1000.0
            frames.append(frame_ms)
            if frame_ms>12000.0:
                abort_reason="individual_real_frame_over_12_seconds"
                break
        var mean_ms := 0.0
        for ms in frames:
            mean_ms += ms
        mean_ms /= float(frames.size())
        _record({"step":step,"target_tris":total,"instances":count,"submitted_tris":count*T,
          "status":"MEASURED","frame_samples_ms":frames,
          "mean_frame_wall_ms":snappedf(mean_ms,.01),
          "estimated_fps_from_frame_wall":snappedf(1000.0/maxf(1.0,mean_ms),.01),\n          "warmup_excluded":true,
          "instance_setup_ms":setup_ms,
          "godot_primitives_monitor_includes_passes":Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME),
          "godot_draw_calls":Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),
          "godot_video_mem_bytes_reported":Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED)})
        if step in [1,10,20,50,75,100]:
            var capture := vp.get_texture().get_image()
            if capture!=null and capture.get_size()==VIEW:
                capture.save_png("res://build/d20-50m/real_step_%03d.png"%step)
        # Do NOT stop on a merely slow software-GPU frame; try all 100 requested
        # exact steps. Stop only at a pathological 12-second single-frame cost.
    _record({"kind":"footer","first":first,"last":last,"stop_reason":abort_reason})
    output.close()
    quit(0)
