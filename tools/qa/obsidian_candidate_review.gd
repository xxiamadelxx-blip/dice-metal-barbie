extends SceneTree
## Private review fixture; staged macro + all faces, then authentic main-scene rolls.
## MSAA is fixture-only. Camera/mechanics are restored before the playable captures.
const Ico=preload("res://src/core/icosahedron.gd")
const Body=preload("res://src/dice/d20_body.gd")
const Premium=preload("res://src/visual/premium_finish.gd")
var candidate_path := ""
var output_dir := ""
var roll_only := false
var failures=[]
func _initialize():
    for arg in OS.get_cmdline_user_args():
        if arg == "--roll-only":roll_only=true
        if arg.begins_with("--candidate="):candidate_path=arg.trim_prefix("--candidate=")
        if arg.begins_with("--output="):output_dir=arg.trim_prefix("--output=")
    if candidate_path.is_empty() or not candidate_path.begins_with("res://") or output_dir.is_empty():
        push_error("Use -- --candidate=res://private-candidate.glb --output=res://build/review")
        quit(2);return
    if not ResourceLoader.exists(candidate_path):
        push_error("Candidate has not been imported by Godot");quit(2);return
    DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output_dir))
    call_deferred("run")
func check(ok:bool,why:String):
    if not ok:failures.append(why);push_error(why)
func replace_art(body:RigidBody3D,path:String):
    var old=body.get_node_or_null("BlenderRecessedGLB")
    if old!=null:body.remove_child(old);old.queue_free()
    var art=(load(path)as PackedScene).instantiate()
    art.name="BlenderRecessedGLB";body.add_child(art)
func shot(name:String):
    for i in range(5):await process_frame
    await RenderingServer.frame_post_draw
    root.get_texture().get_image().save_png(output_dir+"/"+name+".png")
func run():
    root.msaa_3d=Viewport.MSAA_4X
    root.size=Vector2i(720,1280)
    var app=load("res://src/main.tscn").instantiate();root.add_child(app)
    for i in range(15):await process_frame
    var camera:Camera3D
    for child in app.get_children():
        if child is Camera3D:camera=child
        if child.name.begins_with("Idle"):child.queue_free()
        if child is CanvasLayer:child.visible=false
    var original_transform=camera.transform
    var original_size=camera.size
    var face_checks=[]
    if not roll_only:
        var body=Body.new();body.freeze=true;app.add_child(body)
        body.position=Vector3(0,0.8,0);Premium.decorate_die(body,20)
        root.size=Vector2i(900,900)
        camera.position=Vector3(3.4,3.3,4.5);camera.look_at(Vector3(0,.5,0));camera.size=3.2
        for mode in range(2):
            replace_art(body,Premium.SELECTED_D20 if mode==0 else candidate_path)
            body.basis=Basis.IDENTITY
            await shot("macro-control"if mode==0 else "macro-candidate")
        camera.transform=original_transform;camera.size=original_size
        root.size=Vector2i(720,1280)
        for mode in range(2):
            replace_art(body,Premium.SELECTED_D20 if mode==0 else candidate_path)
            for face in range(20):
                body.basis=Basis(Vector3.UP,.35)*Basis(Quaternion(Ico.face_normal(face),Vector3.UP))
                check(Ico.top_value(body.basis)==Ico.numbers()[face],"Frozen face mapping failed")
                face_checks.append({"mode":mode,"face":face,"value":Ico.top_value(body.basis)})
                await shot("overhead-%d-face-%02d"%[mode,face])
        body.queue_free()
    for child in app.get_children():
        if child is CanvasLayer:child.visible=true
    app.call("_select_die_type",20);app.call("_throw_selected_die")
    var live=app.get("active_die")as RigidBody3D
    replace_art(live,candidate_path)
    check(is_equal_approx(live.mass,.045),"Original mass changed")
    check(live.get_node("IcosahedronCollision").shape.points==Ico.vertices(),"Collider changed")
    var elapsed=0.0
    while live.get("rolling")and elapsed<12:
        await physics_frame;elapsed+=1.0/Engine.physics_ticks_per_second
    var result=int(live.get("result"))
    check(result>=1 and result<=20 and result==Ico.top_value(live.basis),"Genuine throw/top mismatch")
    await shot("actual-candidate-game-roll")
    await create_timer(1.0).timeout
    app.call("_request_advanced_throw","1d20+1d6","normal","pair")
    var pool=app.get("physical_pool")as Node3D
    for child in pool.get_children():
        if child is RigidBody3D and child.get_node_or_null("IcosahedronCollision")!=null:replace_art(child,candidate_path)
    elapsed=0.0
    while pool.get("busy")and elapsed<30:
        await physics_frame;elapsed+=1.0/Engine.physics_ticks_per_second
    check(not pool.get("busy"),"Mixed throw did not settle before timeout")
    check(pool.get("last_physical_error")=="","Mixed physical throw failed")
    check(pool.get("last_result").get("ok",false),"Mixed throw did not produce a verified result")
    check(camera.transform==original_transform and camera.size==original_size,"Product camera changed")
    await shot("actual-candidate-mixed-roll")
    await create_timer(1.0).timeout
    var receipt={"candidate_sha256":FileAccess.get_sha256(candidate_path),"single_result":result,"mixed":pool.get("last_result"),"faces":face_checks,"mass":.045,"renderer":RenderingServer.get_video_adapter_name(),"physics_changes":false,"product_camera_unchanged":true,"msaa":root.msaa_3d,"failures":failures,"macro_note":"staged inspection camera only; main overhead camera restored"}
    FileAccess.open(output_dir+"/runtime-receipt.json",FileAccess.WRITE).store_string(JSON.stringify(receipt,"  "))
    print("OBSIDIAN_CANDIDATE_REAL_GAME ",JSON.stringify(receipt))
    quit(0 if failures.is_empty()else 1)
