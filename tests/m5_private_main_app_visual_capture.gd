extends SceneTree
## Real main scene, real approved overhead camera, original owner selected 500k art.
const Art = preload("res://src/dice/m5_original_obsidian_art.gd")
const N_TRIALS := 1
var failures := 0
func _initialize() -> void:
    call_deferred("_run")
func _shot(label: String) -> void:
    for f in range(3):
        await process_frame
    await RenderingServer.frame_post_draw
    var image:=root.get_texture().get_image()
    if image==null or image.is_empty():
        failures+=1
        push_error("M5 app visible screen image null "+label)
        return
    var target:="res://build/m5_private_app/real_%s.png"%label
    var rc:=image.save_png(target)
    if rc!=OK:
        failures+=1
    print("M5_REAL_APP_SCREEN ",label," size=",image.get_size()," path=",target," result=",rc)
func _run() -> void:
    ProjectSettings.set_setting(Art.PROJECT_FLAG, true)
    DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://build/m5_private_app"))
    var packed:=load("res://src/main.tscn") as PackedScene
    assert(packed!=null)
    var scene:=packed.instantiate() as Node3D
    root.add_child(scene)
    for i in range(14):
        await process_frame
    scene.call("_select_die_type",20)
    await _shot("d20_selected_before_roll")
    scene.call("_throw_physical_d20")
    var body := scene.get_node_or_null("PhysicalD20") as RigidBody3D
    if body==null:
        failures+=1
        push_error("No actual main-scene Jolt D20 after throw")
        quit(28)
        return
    print("M5_APP_D20_ACTIVE ",body.m5_original_visual_active," front_camera=",(scene.get_node_or_null("FixedOverheadCamera") as Camera3D).rotation_degrees)
    if not body.m5_original_visual_active:
        failures+=1
    var captured_in_motion:=false
    var completed:=false
    for tick in range(1300):
        await physics_frame
        if tick>24 and not captured_in_motion and body.rolling:
            captured_in_motion=true
            await _shot("actual_physical_d20_in_motion")
        if not body.rolling:
            completed=true
            break
    if not completed:
        failures+=1
        push_error("Jolt premium die did not stop within 1300 physics frames")
    else:
        if not body.failure.is_empty():
            failures+=1
            push_error("Jolt actual main app failed "+body.failure)
        if body.result != body.top_visible_value():
            failures+=1
            push_error("In main app returned face differs from visible gold figure")
        if scene.last_result != body.result:
            failures+=1
            push_error("App overlay result differs from genuine physical outcome")
        print("M5_REAL_MAIN_APP_JOLT_VISIBLE_RESULT ",body.result," actual_top=",body.top_visible_value()," overlay=",scene.last_result," elapsed=",body.elapsed)
        await _shot("actual_physical_d20_settled")
    print("M5_REAL_MAIN_APP_PRIVATE_MOBILE_RESULT failures=",failures," captured_motion=",captured_in_motion," completed=",completed," renderer=",RenderingServer.get_current_rendering_method()," gpu=",RenderingServer.get_video_adapter_name())
    quit(0 if failures==0 and completed and captured_in_motion else 27)