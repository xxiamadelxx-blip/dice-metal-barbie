extends SceneTree
const CriticalAura = preload("res://src/visual/critical_aura.gd")
const Ico = preload("res://src/core/icosahedron.gd")
const RealD20 = preload("res://src/dice/d20_body.gd")
const Premium = preload("res://src/visual/premium_finish.gd")
const Octa = preload("res://src/core/octahedron.gd")
const Dodeca = preload("res://src/core/dodecahedron.gd")
const Tetra = preload("res://src/core/tetrahedron.gd")
## Cloud native visual fallback for inspecting the actual Godot render output.
## Runs under Xvfb/Mesa, not an Android APK. NEVER claim handset equivalence.

func _initialize() -> void:
    call_deferred("_run")

func _capture(name: String) -> void:
    await RenderingServer.frame_post_draw
    var rendered: Image = root.get_texture().get_image()
    if rendered == null or rendered.is_empty():
        push_error("No rendered frame: %s" % name)
        quit(3)
        return
    var dest := "res://qa-evidence/" + name + ".png"
    var err := rendered.save_png(dest)
    if err != OK:
        push_error("Cannot save native capture: %s error %d" % [dest, err])
        quit(4)
        return
    print("Captured actual Godot native renderer frame: %s size=%s" % [dest, rendered.get_size()])

func _run() -> void:
    root.size = Vector2i(720, 1280)
    var packed: PackedScene = load("res://src/main.tscn")
    if packed == null:
        push_error("Main scene unavailable")
        quit(2)
        return
    var scene: Node3D = packed.instantiate()
    root.add_child(scene)
    await create_timer(1.5).timeout
    await _capture("native-01-launch")
    scene.call("_throw_physical_d6")
    await create_timer(0.7).timeout
    await _capture("native-02-moving")
    await create_timer(5.0).timeout
    await _capture("native-03-after")
    # The user-approved concept emphasizes sculptural polyhedra. The old
    # screenshot suite showed D6 only, which looks square from 90° overhead.
    # Also inspect the real faceted D20, not a staged illustration.
    scene.call("_select_die_type", 20)
    scene.call("_throw_physical_d20")
    await create_timer(0.7).timeout
    await _capture("native-04-d20-moving")
    await create_timer(5.0).timeout
    await _capture("native-05-d20-after")
    # This genuine overhead detail view is essential for evaluating whether
    # 3D text and pocket geometry hold up beyond the tiny full-table preview.
    var closeup_camera := scene.get_node_or_null("FixedOverheadCamera") as Camera3D
    var closeup_die := scene.get_node_or_null("PhysicalD20") as RigidBody3D
    if closeup_camera == null or closeup_die == null:
        push_error("Cannot make a truthful native D20 detail capture")
        quit(6)
        return
    var d20_face_value: int = Ico.top_value(closeup_die.global_transform.basis.orthonormalized(), 0.02)
    var d20_hud_value: int = int(scene.get("last_result"))
    if d20_face_value < 1 or d20_face_value != d20_hud_value:
        push_error("Actual D20 Jolt upper face %d != HUD %d" % [d20_face_value, d20_hud_value])
        quit(12)
        return
    print("PASS actual D20 upper physical face = HUD %d" % d20_face_value)
    closeup_camera.size = 3.8
    closeup_camera.position = Vector3(closeup_die.position.x, 18.0, closeup_die.position.z)
    await create_timer(0.5).timeout
    await _capture("native-06-d20-detail")
    # Controlled *visual-only* effect staging on a genuine settled die.
    # NOT evidence that the random physical result was a natural crit.
    # Physics result triggering is separately guarded in main.gd and unit tests.
    var gold_aura := CriticalAura.spawn(closeup_die, 20, 20)
    if gold_aura == null:
        push_error("Unable to stage golden spatial D20 aura in native renderer")
        quit(7)
        return
    await create_timer(0.18).timeout
    await _capture("native-07-staged-gold-pulse")
    await create_timer(1.1).timeout
    var red_aura := CriticalAura.spawn(closeup_die, 20, 1)
    if red_aura == null:
        push_error("Unable to stage crimson spatial D20 aura in native renderer")
        quit(8)
        return
    await create_timer(0.18).timeout
    await _capture("native-08-staged-crimson-pulse")
    print("Staged D20 critical wave previews complete; not natural throw evidence.")
    # New authored Blender D8/D12 art MUST be inspected inside real Godot,
    # not only as standalone Blender camera renders. Real physical throws.
    await create_timer(1.0).timeout
    for sides in [8,12,4]:
        closeup_camera.size = 14.2
        closeup_camera.position = Vector3(0, 18.0, 1.5)
        scene.call("_select_die_type", sides)
        scene.call("_throw_selected_die")
        await create_timer(7.0).timeout
        var die := scene.get_node_or_null("PhysicalD%d" % sides) as RigidBody3D
        if die == null:
            push_error("Missing real physical D%d for imported GLB macro QA" % sides)
            quit(9)
            return
        # The image must reflect a completed physical result, not a random
        # airborne pose; the legacy HUD result is the oracle for all five dice.
        var rolled_number: int = int(scene.get("last_result"))
        if rolled_number < 1 or rolled_number > sides:
            push_error("D%d visual QA requires a completed physical roll, got %d" % [sides, rolled_number])
            quit(11)
            return
        # Native 14.2 orthographic camera after real Jolt roll; no staged pose.
        var normal_name: String = {8:"native-12-d8-normal",12:"native-13-d12-normal",
            4:"native-14-d4-normal"}[sides]
        await _capture(normal_name)
        print("NORMAL_VIEW Jolt D%d physically settled result = %d, camera size 14.2" % [sides, rolled_number])
        var pose: Basis = die.global_transform.basis.orthonormalized()
        var physical_face_value := -1
        match sides:
            4: physical_face_value = Tetra.top_value(pose)
            8: physical_face_value = Octa.top_value(pose)
            12: physical_face_value = Dodeca.top_value(pose)
        if physical_face_value != rolled_number:
            push_error("D%d actual top value %d differs from displayed %d" % [
                sides, physical_face_value, rolled_number])
            quit(13)
            return
        print("PASS physical D%d upper face/apex == HUD value %d" % [sides, rolled_number])
        var imported := die.get_node_or_null("BlenderRecessedGLB") as Node3D
        if imported == null:
            push_error("D%d is showing old procedural fallback, not new Blender GLB" % sides)
            quit(10)
            return
        closeup_camera.size = 3.8
        closeup_camera.position = Vector3(die.position.x, 18.0, die.position.z)
        await create_timer(0.4).timeout
        var output: String = {8:"native-09-d8-detail",12:"native-10-d12-detail",
            4:"native-11-d4-apex-detail"}[sides]
        await _capture(output)
    # Staged art visibility proof only. The clone is NOT thrown and cannot
    # emit a roll_completed event or influence game results. It isolates
    # physical 6/9 underline legibility in the actual Godot renderer.
    var staged := RealD20.new() as RigidBody3D
    staged.name = "STAGED_UnderlineInspection_Only"
    staged.freeze = true
    staged.collision_layer = 0
    staged.collision_mask = 0
    scene.add_child(staged)
    staged.position = Vector3(0, 1.1, 0)
    Premium.decorate_die(staged, 20)
    if die != null:
        die.visible = false
    closeup_camera.size = 3.8
    closeup_camera.position = Vector3(0, 18.0, 0)
    for target in [6, 9]:
        var face_index: int = Ico.numbers().find(target)
        if face_index == -1:
            push_error("Staged 6/9 proof has no numeric face %d" % target)
            quit(14)
            return
        var up_axis: Vector3 = Ico.face_normal(face_index)
        staged.basis = Basis(Quaternion(up_axis, Vector3.UP))
        await create_timer(0.35).timeout
        await _capture("native-15-staged-d20-six-underbar" if target == 6 else
                       "native-16-staged-d20-nine-underbar")
    print("Native Godot QA complete: 5 physical dice and STAGED (not rolled) 6/9 engraving views.")
    quit(0)
