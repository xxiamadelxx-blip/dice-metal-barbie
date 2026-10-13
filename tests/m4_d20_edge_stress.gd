extends SceneTree
## REAL 120Hz-Jolt multi-body trials. No predetermined faces or synthetic
## outcomes. The printed top face must match a naturally sleeping D20.
const Pool = preload("res://src/core/physical_roll_pool.gd")
const Ico = preload("res://src/core/icosahedron.gd")
const D20 = preload("res://src/dice/d20_body.gd")
const TRIALS := 12
var checked := 0
var errors := 0
var recoveries := 0
var maximum_recoveries := 0
func _initialize() -> void:
    call_deferred("_run")
func _check(ok: bool, detail: String) -> void:
    checked += 1
    if not ok:
        errors += 1
        push_error(detail)
func _run() -> void:
    var scene := load("res://src/main.tscn").instantiate() as Node3D
    root.add_child(scene)
    await process_frame
    var pool := Pool.new()
    pool.name="M4D20EdgeReliabilityCandidate"
    scene.add_child(pool)
    var physical_failures: Array[String] = []
    pool.pool_failed.connect(func(reason: String):
        physical_failures.append(reason))
    for trial in range(TRIALS):
        physical_failures.clear()
        var started := pool.begin("2d6+1d20-3")
        _check(started,"M4 true Jolt mixed D20 did not start trial="+str(trial))
        if not started:
            break
        var ticks := 0
        while bool(pool.get("busy")) and ticks<16000:
            ticks+=1
            await physics_frame
        _check(not bool(pool.get("busy")),
            "Actual four? 3-body mixed pool timed out trial="+str(trial))
        _check(physical_failures.is_empty(),
            "Real D20 Jolt edge caused aborted outcome trial="+str(trial)+
            " details="+str(physical_failures))
        var receipt: Dictionary=pool.get("last_result")
        _check(bool(receipt.get("ok",false)),
            "No real completed Jolt receipt trial="+str(trial))
        if not bool(receipt.get("ok",false)):
            break
        var original: Array=pool.get("_active")
        _check(original.size()==3,
            "Mixed physical source bodies missing trial="+str(trial))
        var d20: RigidBody3D=null
        for die in original:
            if (die as RigidBody3D).has_method("numeral_node"):
                d20=die as RigidBody3D
        _check(d20!=null and d20.sleeping,
            "No naturally settled original D20 rigid body")
        if d20==null:
            break
        var face: int=Ico.top_value(d20.global_transform.basis.orthonormalized(),0.02)
        _check(face>=1 and face==int(d20.get("result")),
            "Physical top-facing D20 face changed / was invented")
        var hits := int(d20.get("edge_recovery_count"))
        recoveries+=hits
        maximum_recoveries=maxi(maximum_recoveries,hits)
        _check(hits<=D20.MAX_EDGE_RECOVERY_ATTEMPTS,
            "D20 applied unlimited physical edge impulses")
        print("M4_D20_TRUE_JOLT_EDGE trial=%d actual=%d recoveries=%d" %
            [trial,face,hits])
    print("M4_D20_REAL_EDGE_STRESS trials=%d checks=%d failures=%d recoveries=%d max=%d" %
        [TRIALS,checked,errors,recoveries,maximum_recoveries])
    quit(0 if errors==0 and checked>=TRIALS*6 else 1)
