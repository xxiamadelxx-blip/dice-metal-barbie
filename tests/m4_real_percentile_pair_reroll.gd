extends SceneTree
## Actual Godot 4.6/Jolt physical two-source percentile reroll acceptance.
## Only real sleeping rigid-body normals are used, with every original face.
const Pool = preload("res://src/core/physical_roll_pool.gd")
const Store = preload("res://src/core/roll_persistence.gd")
const Kite = preload("res://src/core/trapezohedron.gd")
const FILE := "user://m4_pair_physical_qa.json"
var checks := 0
var errors := 0
var last: Dictionary = {}
var failure := ""

func _initialize() -> void:
    call_deferred("_run")

func verify(valid: bool, info: String) -> void:
    checks += 1
    if not valid:
        errors += 1
        push_error(info)

func _done(result: Dictionary) -> void:
    last = result

func _failed(reason: String) -> void:
    failure = reason

func _wait(pool: Node3D) -> bool:
    for tick in range(15000):
        await physics_frame
        if not bool(pool.get("busy")):
            return true
    return false

func _run() -> void:
    var abs_file := ProjectSettings.globalize_path(FILE)
    if FileAccess.file_exists(FILE):
        DirAccess.remove_absolute(abs_file)
    var scene := load("res://src/main.tscn").instantiate() as Node3D
    root.add_child(scene)
    await process_frame
    var pool := Pool.new()
    scene.add_child(pool)
    pool.connect("pool_completed",Callable(self,"_done"))
    pool.connect("pool_failed",Callable(self,"_failed"))
    verify(pool.begin("1d100+1d6-2","normal","pair"),
        "Initial paired physical D100 mixed throw rejected")
    verify(await _wait(pool),"Initial two D10 Jolt bodies did not settle")
    verify(failure.is_empty() and bool(last.get("ok",false)),
        "Initial real paired-percentile faces invalid: "+failure)
    if errors:
        quit(1)
        return
    var original: Dictionary = last.duplicate(true)
    var bodies: Array = pool.get("_active")
    verify(bodies.size()==3,
        "One logical percentile pair PLUS D6 must be three real rigid bodies")
    var tens: RigidBody3D = bodies[0]
    var ones: RigidBody3D = bodies[1]
    var d6: RigidBody3D = bodies[2]
    var kept_d6: int = int(d6.get("result"))
    var previous_pairs: Array = original["groups"][0]["percentile_source_d10_attempts"][0]
    verify(previous_pairs.size()==1,
        "First physical percentile throw must have one pair of source faces")
    var old_pair: Array = previous_pairs[0]
    verify(int(old_pair[0])==int(tens.get("result")) and
        int(old_pair[1])==int(ones.get("result")),
        "First source values do not match two genuine Jolt upper kite faces")
    var memory := Store.new(FILE)
    verify(memory.load_state().get("ok",false),
        "Cannot initialize isolated offline real physical source store")
    verify(memory.append_physical_result(original).get("ok",false),
        "Cannot persist original Jolt percentile pair")
    for step in range(2):
        last = {}
        failure = ""
        verify(pool.reroll_one(0,0),
            "Selecting logical physical paired D100 must relaunch two D10")
        verify(await _wait(pool),"Both actual D10 failed to settle in percentile reroll")
        verify(failure.is_empty() and bool(last.get("ok",false)),
            "Physical percentile pair failed: "+failure)
        if not bool(last.get("ok",false)):
            break
        var active: Array = pool.get("_active")
        verify(active.size()==3 and active[0]==tens and active[1]==ones and
            active[2]==d6,"Reroll must reuse BOTH original D10 and retain D6 body")
        verify(d6.freeze and int(d6.get("result"))==kept_d6,
            "Unselected genuine D6 must keep actual prior sleeping top face")
        verify(int(last.get("reroll_source_body_count",0))==2,
            "One percentile reroll must have exactly two real Jolt sources")
        var pairs: Array = last["groups"][0]["percentile_source_d10_attempts"][0]
        verify(pairs.size()==step+2 and pairs[0]==old_pair,
            "Original real percentile D10 pair erased after physical reroll")
        var final_digits: Array = pairs[-1]
        verify(final_digits.size()==2 and
            int(final_digits[0])==int(tens.get("result")) and
            int(final_digits[1])==int(ones.get("result")),
            "Rerolled true physical D10 sources differ from history")
        verify(Kite.top_value(10,tens.global_transform.basis.orthonormalized())==
            int(tens.get("result")) and
            Kite.top_value(10,ones.global_transform.basis.orthonormalized())==
            int(ones.get("result")),
            "Physical kite normals do not agree with BOTH actual source callbacks")
        var computed := int(last["modifier"])
        for group in last["groups"]:
            computed += int(group["subtotal"])
        verify(computed==int(last["total"]) and
            int(last["groups"][1]["kept_faces"][0])==kept_d6,
            "Recomputed mixed total or nonselected source is incorrect")
        verify(memory.append_physical_result(last).get("ok",false),
            "Independent persistence rejected genuine percentile reroll trace")
        print("M4_PAIR_JOLT_REROLL #%d pairs=%s total=%d" %
            [step+1,JSON.stringify(pairs),int(last["total"])])
    if bool(last.get("ok",false)):
        verify(not pool.reroll_one(10,10),"Invalid D100 source must be refused")
        var previous_total := int(last["total"])
        verify(int(pool.get("last_result")["total"])==previous_total,
            "Invalid percentile source selection mutated last physical result")
        var reopened := Store.new(FILE)
        verify(reopened.load_state().get("ok",false),
            "All genuine percentile source traces must survive offline reopen")
        var entries: Array = reopened.snapshot()["history"]
        verify(entries.size()==3,
            "Missing first, second or third actual physical pair operation")
        verify(entries[0]["groups"][0]["percentile_source_d10_attempts"][0].size()==3,
            "Two real rethrows must preserve three source D10 pairs offline")
    if FileAccess.file_exists(FILE):
        DirAccess.remove_absolute(abs_file)
    print("M4_REAL_PAIR_JOLT QA %d checks / %d failures" % [checks,errors])
    quit(0 if errors==0 else 1)
