extends SceneTree
## Private native test. Original owner BlenderKit GLB installed ONLY on local machine.
const D20 = preload("res://src/dice/d20_body.gd")
const Ico = preload("res://src/core/icosahedron.gd")
const M5Art = preload("res://src/dice/m5_original_obsidian_art.gd")
const Pool = preload("res://src/core/physical_roll_pool.gd")
var checks := 0
var fails := 0
func _initialize() -> void:
    call_deferred("_run")
func verify(cond: bool, explanation: String) -> void:
    checks += 1
    if not cond:
        fails += 1
        push_error("M5_JOLT_FAIL " + explanation)
func _run() -> void:
    print("M5_JOLT_ENGINE ", ProjectSettings.get_setting("physics/3d/physics_engine"))
    ProjectSettings.set_setting(M5Art.PROJECT_FLAG, true)
    var die := D20.new()
    die.freeze = true
    root.add_child(die)
    await process_frame
    verify(die.m5_original_visual_active, "Real licensed 500k mesh must be enabled")
    var visual := die.get_node_or_null("M5OriginalObsidian500KVisual") as Node3D
    verify(visual != null, "M5 owner art node not found")
    var collider := die.get_node_or_null("IcosahedronCollision") as CollisionShape3D
    verify(collider != null and collider.shape is ConvexPolygonShape3D, "Original Jolt collider must remain original convex mesh")
    if collider != null:
        verify((collider.shape as ConvexPolygonShape3D).points.size() == 12, "Collider must stay 12 original icosahedral vertices")
    if visual != null:
        verify(absf(visual.basis.orthonormalized().determinant() - 1.0) < .01, "Visual rotation determinant is not +1")
        verify(absf(visual.scale.x - M5Art.VISUAL_SCALE)<.00001, "Incorrect size")
    var found := {}
    var pool := Pool.new()
    root.add_child(pool)
    for i in range(20):
        var normal := Ico.face_normal(i)
        var turn := Quaternion(normal, Vector3.UP)
        die.global_transform = Transform3D(Basis(turn), Vector3(0,2.0,0))
        var printed: int = M5Art.printed_value_for_face(i)
        var actual: int = die.top_visible_value()
        var pooled: int = int(pool.call("_actual_top",die,20))
        verify(actual == printed, "Visible die mismatch face="+str(i)+" expected="+str(printed)+" actual="+str(actual))
        verify(pooled == printed, "M4 mixed-die pool mismatch on face="+str(i))
        verify(not found.has(printed), "Duplicate printed number "+str(printed))
        found[printed] = true
    verify(found.size() == 20, "Twenty unique physical printed outcomes required")
    for i in range(20):
        var opposite_idx := -1
        for j in range(20):
            if Ico.face_normal(i).dot(Ico.face_normal(j)) < -.999:
                opposite_idx=j
                break
        verify(opposite_idx >= 0, "Missing antipodal face")
        if opposite_idx >= 0:
            verify(M5Art.printed_value_for_face(i)+M5Art.printed_value_for_face(opposite_idx)==21,
                "Opposite printed number pair must add to 21")
    die.queue_free()
    pool.queue_free()
    await process_frame
    # Exercise original user-approved Jolt physical dynamics without forcing a result.
    var floor := StaticBody3D.new()
    floor.name = "PhysicalTable"
    root.add_child(floor)
    var floor_shape := CollisionShape3D.new()
    var floor_box := BoxShape3D.new()
    floor_box.size = Vector3(30.0,.2,30.0)
    floor_shape.shape = floor_box
    floor.position=Vector3(0,-0.14,0)
    floor.add_child(floor_shape)
    var completed := 0
    for k in range(12):
        var throw := D20.new()
        throw.name = "Original500kJoltTrial"+str(k)
        root.add_child(throw)
        verify(throw.m5_original_visual_active,"Actual throw must use private model")
        throw.throw_from_top()
        var settled := false
        for tick in range(1400):
            await physics_frame
            if not throw.rolling:
                settled = true
                break
        verify(settled,"Actual real Jolt die did not stop in time trial="+str(k))
        if settled:
            verify(throw.failure.is_empty(),"Actual Jolt roll failed trial="+str(k)+" reason="+throw.failure)
            var visible := throw.top_visible_value()
            verify(throw.result == visible,"Actual Jolt return must equal visible gold glyph trial="+str(k))
            verify(visible >=1 and visible<=20,"Gold glyph outside permitted range")
            completed+=1 if throw.result==visible and throw.failure.is_empty() else 0
            print("M5_JOLT_REAL_ROLL trial=",k," outcome=",throw.result," visible=",visible," settle_seconds=",throw.elapsed," recovery=",throw.edge_recovery_count," pos=",throw.position)
        throw.queue_free()
        await process_frame
    print("M5_JOLT_REAL_PRIVATE_ORIGINAL_D20_RESULT checks=",checks," failures=",fails," successful_rolls=",completed," all20_mapping=",found.size()==20)
    quit(0 if fails==0 and completed==12 else 27)