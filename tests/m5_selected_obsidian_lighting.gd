extends SceneTree
const Ico=preload("res://src/core/icosahedron.gd")
const Premium=preload("res://src/visual/premium_finish.gd")
const Body=preload("res://src/dice/d20_body.gd")
func _initialize():call_deferred("run")
func run():
    if not Premium._selected_obsidian_available():
        print("NOT_VERIFIED: private selected GLB/HDR required")
        quit(2)
        return
    DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://build/lighting-proof"))
    var app=load("res://src/main.tscn").instantiate()
    root.add_child(app)
    for i in range(15):await process_frame
    for child in app.get_children():
        if child.name.begins_with("Idle"):child.queue_free()
    var body=RigidBody3D.new()
    body.set_script(Body)
    body.freeze=true
    app.add_child(body)
    Premium.decorate_die(body,20)
    body.position=Vector3(0,0.8,1.5)
    var env:Environment
    for child in app.get_children():
        if child is WorldEnvironment:env=child.environment
    var camera:Camera3D
    for child in app.get_children():
        if child is Camera3D:camera=child
    var original=camera.transform
    var original_size=camera.size
    var shader=Shader.new()
    shader.code="shader_type sky; uniform sampler2D panorama : source_color, filter_linear_mipmap, repeat_enable; void sky(){ COLOR=texture(panorama,SKY_COORDS).rgb; }"
    var original_sky=ShaderMaterial.new()
    original_sky.shader=shader
    original_sky.set_shader_parameter("panorama",load(Premium.SELECTED_STUDIO))
    var selected=env.sky.sky_material
    var receipts=[]
    for mode in range(2):
        env.sky.sky_material=original_sky if mode==0 else selected
        for face in range(20):
            for yaw in range(3):
                body.basis=Basis(Vector3.UP,float(yaw)*TAU/3)*Basis(Quaternion(Ico.face_normal(face),Vector3.UP))
                var observed=Ico.top_value(body.basis)
                assert(observed==Ico.numbers()[face])
                for i in range(3):await process_frame
                await RenderingServer.frame_post_draw
                root.get_texture().get_image().save_png("res://build/lighting-proof/pose-%d-face-%02d-yaw-%d.png"%[mode,face,yaw])
                receipts.append({"mode":mode,"face":face,"yaw":yaw,"observed":observed,"expected":Ico.numbers()[face]})
    FileAccess.open("res://build/lighting-proof/pose-receipt.json",FileAccess.WRITE).store_string(JSON.stringify(receipts,"  "))
    assert(camera.transform==original and camera.size==original_size)
    print("STUDY_COMPLETE: staged actual game camera; no rolled result claimed")
    quit()
