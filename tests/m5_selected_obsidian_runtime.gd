extends SceneTree
const Ico=preload("res://src/core/icosahedron.gd")
const Premium=preload("res://src/visual/premium_finish.gd")
var failures=[]
func _initialize(): call_deferred("run")
func check(ok:bool,why:String):
    if not ok: failures.append(why);push_error(why)
func shot(name:String):
    await RenderingServer.frame_post_draw
    root.get_texture().get_image().save_png("res://build/approved-runtime-proof/"+name+".png")
func run():
    if not Premium._selected_obsidian_available():
        print("NOT_VERIFIED: private selected GLB/HDR required")
        quit(2)
        return
    DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://build/approved-runtime-proof"))
    var app=load("res://src/main.tscn").instantiate()
    root.add_child(app)
    for i in range(15):await process_frame
    check(Premium._selected_obsidian_available(),"Approved private GLB/HDR unavailable")
    var camera:Camera3D
    for child in app.get_children():
        if child is Camera3D:camera=child
    if camera==null:
        push_error("Original main-scene camera missing")
        quit(2)
        return
    var camera_transform=camera.transform
    var camera_size=camera.size
    await shot("game-before-roll")
    app.call("_select_die_type",20)
    app.call("_throw_selected_die")
    var die=app.get("active_die") as RigidBody3D
    check(die!=null,"Real D20 body missing")
    check(is_equal_approx(die.mass,.045),"Original D20 mass changed")
    var shape=die.get_node("IcosahedronCollision").shape as ConvexPolygonShape3D
    check(shape.points==Ico.vertices(),"Canonical collider changed")
    check(die.get_node_or_null("BlenderRecessedGLB")!=null,"Selected art did not attach")
    var elapsed=0.0
    while die.get("rolling") and elapsed<12:
        await physics_frame
        elapsed+=1.0/Engine.physics_ticks_per_second
    check(die.get("result")>=1 and die.get("result")<=20,"Real throw did not finish")
    check(die.get("result")==Ico.top_value(die.basis),"Visible upper face differs from physical result")
    check(camera.transform==camera_transform and camera.size==camera_size,"Approved overhead camera changed")
    for i in range(12):await process_frame
    await shot("game-d20-after-roll")
    var basic_value=die.get("result")
    app.call("_request_advanced_throw","1d20+1d6","normal","pair")
    var pool=app.get("physical_pool") as Node3D
    check(pool!=null,"Real M4 pool missing")
    elapsed=0
    while pool.get("busy") and elapsed<30:
        await physics_frame
        elapsed+=1.0/Engine.physics_ticks_per_second
    var d20:RigidBody3D
    for child in pool.get_children():
        if child is RigidBody3D and child.get_node_or_null("IcosahedronCollision")!=null:d20=child
    check(d20!=null and d20.get_node_or_null("BlenderRecessedGLB")!=null,"M4 D20 lost selected art")
    check(pool.is_connected("critical_visual_requested",Callable(app,"_show_pool_critical")),"Presentation critical signal disconnected")
    check(pool.get("last_physical_error")=="","M4 physical pool failed")
    for i in range(12):await process_frame
    await shot("game-mixed-pool-after-roll")
    var outcome={"basic_d20":basic_value,"pool":pool.get("last_result"),"collider":"canonical unchanged","mass":.045,"camera":"original overhead unchanged","selected_glb_sha":Premium.SELECTED_D20_SHA256,"selected_hdr_sha":Premium.SELECTED_STUDIO_SHA256,"failures":failures}
    FileAccess.open("res://build/approved-runtime-proof/runtime-receipt.json",FileAccess.WRITE).store_string(JSON.stringify(outcome,"  "))
    print("APP_SELECTED_OBSIDIAN ",JSON.stringify(outcome))
    quit(0 if failures.is_empty() else 1)
