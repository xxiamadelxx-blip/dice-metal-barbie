extends SceneTree
## M4 true selective physical Jolt rerolls (not any deterministic fake).
## The unchanged real source dice stay on table; selected D6 gets an entirely
## new physical throw while its first actual face remains in reroll history.
const Pool = preload("res://src/core/physical_roll_pool.gd")
const Cube = preload("res://src/core/cube_symmetry.gd")
var checks := 0
var failures := 0
var observed: Dictionary = {}
var failed_message := ""

func _initialize() -> void:
    call_deferred("_run")

func _check(ok: bool, why: String) -> void:
    checks += 1
    if not ok:
        failures += 1
        push_error(why)

func _completed(result: Dictionary) -> void:
    observed = result

func _failed(why: String) -> void:
    failed_message = why

func _wait(pool: Node3D) -> bool:
    for tick in range(10000):
        await physics_frame
        if not bool(pool.get("busy")):
            return true
    return false

func _run() -> void:
    var scene := load("res://src/main.tscn").instantiate() as Node3D
    root.add_child(scene)
    await process_frame
    var pool := Pool.new()
    scene.add_child(pool)
    pool.connect("pool_completed",Callable(self,"_completed"))
    pool.connect("pool_failed",Callable(self,"_failed"))
    _check(pool.call("begin","2d6+1d20-3"),
        "M4 initial mixed physical cast did not start")
    _check(await _wait(pool),"Initial real Jolt throw hung")
    _check(failed_message.is_empty() and bool(observed.get("ok",false)),
        "Initial real mixed result physically invalid")
    if failures>0:
        quit(1)
        return
    var original: Dictionary = observed.duplicate(true)
    var original_bodies: Array = pool.get("_active")
    _check(original_bodies.size()==3,"Expected 2 real D6 and 1 genuine D20")
    var selected: RigidBody3D = original_bodies[0]
    var unchanged_d6: RigidBody3D = original_bodies[1]
    var unchanged_d20: RigidBody3D = original_bodies[2]
    var preserved_6: int = int(unchanged_d6.get("result"))
    var preserved_20: int = int(unchanged_d20.get("result"))
    var first_face: int = int(selected.get("result"))
    _check(first_face==int(original["groups"][0]["kept_faces"][0]),
        "Initial physical source value mismatch")
    for reroll_index in range(2):
        observed = {}
        failed_message = ""
        _check(pool.call("reroll_one",0,0),
            "Cannot request targeted real D6 reroll")
        _check(await _wait(pool),"Selected source did not finish real Jolt reroll")
        _check(failed_message.is_empty() and bool(observed.get("ok",false)),
            "Physical reroll failed instead of returning actual face")
        if failed_message!="" or not bool(observed.get("ok",false)):
            break
        var bodies: Array = pool.get("_active")
        _check(bodies.size()==3 and bodies[0]==selected and
            bodies[1]==unchanged_d6 and bodies[2]==unchanged_d20,
            "Reroll destroyed/duplicated other physical source dice")
        _check(unchanged_d6.freeze and unchanged_d20.freeze,
            "Kept sources must remain held visibly in their real final poses")
        _check(int(unchanged_d6.get("result"))==preserved_6 and
            int(unchanged_d20.get("result"))==preserved_20,
            "Unselected physical source values changed during reroll")
        _check(Cube.top_value(selected.global_transform.basis.orthonormalized())==
            int(selected.get("result")), "Selected D6 actual top face diverges")
        var trace: Array = observed["groups"][0]["attempts"][0]
        _check(trace.size()==reroll_index+2 and trace[0]==first_face,
            "Original actual upper face missing from Jolt reroll history")
        _check(trace[-1]==selected.get("result"),
            "Final logged reroll face not physically visible")
        var expected := int(observed["modifier"])
        for group in observed["groups"]:
            expected += int(group["subtotal"])
        _check(expected==int(observed["total"]),
            "Updated mixed formula total ignores physically rerolled face")
        _check(int(observed.get("reroll_attempts_on_selected_die",0))==
            reroll_index+2, "Physical reroll metadata inconsistent")
        print("M4_REAL_REROLL #%d true_face=%d total=%d" %
            [reroll_index+1,int(selected.get("result")),int(observed["total"])])
    # The selected D20 can also be rerolled physically. A natural 1/20
    # critical must refer to its NEW actual uppermost face, without creating
    # an aura from modifier arithmetic or another body.
    observed = {}
    failed_message = ""
    var first_d20 := preserved_20
    var current_first_d6: int = int(selected.get("result"))
    _check(pool.call("reroll_one",1,0),
        "Cannot physically reroll selected original D20 after D6 rerolls")
    _check(await _wait(pool),"Actual selected D20 did not settle")
    _check(failed_message.is_empty() and bool(observed.get("ok",false)),
        "D20 reroll failed to return genuine top-face evidence")
    if bool(observed.get("ok",false)):
        var d20_series: Array = observed["groups"][1]["attempts"][0]
        _check(d20_series.size()==2 and int(d20_series[0])==first_d20,
            "D20 reroll dropped initial real upper face")
        var new_d20 := int(unchanged_d20.get("result"))
        _check(int(d20_series[-1])==new_d20 and new_d20>=1 and new_d20<=20,
            "Rerolled D20 upper face not physically valid")
        _check(int(selected.get("result"))==current_first_d6 and
            int(unchanged_d6.get("result"))==preserved_6,
            "D20 reroll silently changed other real D6 source values")
        var critical := str(observed.get("natural_d20_critical","none"))
        var expected_critical := "success" if new_d20==20 else ("failure" if new_d20==1 else "none")
        _check(critical==expected_critical,
            "Selected D20 natural critical did not match its real source")
        _check(bool(observed.get("all_source_bodies_remain_visible",false)),
            "D20 physical reroll hid other dice from the table")
    var last_verified := observed.duplicate(true)
    _check(not pool.call("reroll_one",15,15),
        "Nonexistent die selection must not invent physical outcomes")
    _check(pool.get("last_result")==last_verified,
        "Invalid reroll changed last valid physical result")
    # Two original physical D10 represent a paired percentile D100.
    observed = {}
    failed_message = ""
    _check(pool.call("begin","1d100+1d6","normal","pair"),
        "Cannot launch a real two-D10 percentile plus D6 pool")
    _check(await _wait(pool),"Initial percentile Jolt pair did not stop")
    if not bool(observed.get("ok",false)):
        _check(false,"Initial physical paired D100 failed")
    else:
        var dice: Array = pool.get("_active")
        _check(dice.size()==3,"A paired D100 plus D6 must have three Jolt bodies")
        if dice.size()==3:
            var tens: RigidBody3D = dice[0]
            var ones: RigidBody3D = dice[1]
            var d6: RigidBody3D = dice[2]
            var original_pair: Array = observed["groups"][0]["percentile_source_d10_faces"][0]
            var six: int = int(d6.get("result"))
            for digit in ["tens","ones"]:
                observed = {}
                failed_message = ""
                _check(pool.call("reroll_one",0,0,digit),
                    "Physical percentile source was not selectable: "+digit)
                _check(await _wait(pool),"Selected genuine percentile D10 stalled")
                _check(failed_message.is_empty() and bool(observed.get("ok",false)),
                    "Authentic percentile source reroll failed")
                if not bool(observed.get("ok",false)):
                    break
                var states: Array = observed["groups"][0]["percentile_source_d10_attempts"][0]
                _check(states.size()==(2 if digit=="tens" else 3),
                    "D100 chronological source evidence was lost")
                _check(int(states[0][0])==int(original_pair[0]) and
                    int(states[0][1])==int(original_pair[1]),
                    "Initial source faces no longer match true Jolt values")
                var last: Array = states[-1]
                _check(int(last[0])==int(tens.get("result")) and
                    int(last[1])==int(ones.get("result")),
                    "Recorded percentile source differs from physical upper faces")
                _check(int(d6.get("result"))==six and d6.freeze,
                    "Rerolled percentile source disturbed the other physical D6")
                var value := ((int(last[0])%10)*10+int(last[1])%10)
                if value==0:
                    value=100
                _check(observed["groups"][0]["observed_faces"][0]==value and
                    observed["total"]==value+six,
                    "Updated D100 result was not derived from two actual D10")
                _check(observed.get("rerolled_percentile_digit","")==digit,
                    "Audit metadata did not name the rerolled physical D10")
            _check(not pool.call("reroll_one",0,0,"not-a-d10"),
                "Invalid pair digit must not initiate a Jolt throw")
    print("M4 real selected-Jolt reroll: %d checks, %d failures" % [checks,failures])
    quit(0 if failures==0 else 1)
