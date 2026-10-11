extends SceneTree
## LIVE Godot Jolt 4.6.3 test. No supplied/random fake dice values.
## Both real physical D10 source bodies of ONE percentile D100 must move,
## settle, keep every previous upper-face pair, and preserve untouched D4.
const Pool = preload("res://src/core/physical_roll_pool.gd")
const Store = preload("res://src/core/roll_persistence.gd")
const FILE := "user://m4_percentile_physical_qa.json"
var checks := 0
var failures := 0
var latest: Dictionary = {}
var physical_failure := ""
func _initialize() -> void:
    call_deferred("_run")
func _check(good: bool, label: String) -> void:
    checks += 1
    if not good:
        failures += 1
        push_error(label)
func _done(v: Dictionary) -> void:
    latest = v
func _failed(reason: String) -> void:
    physical_failure = reason
func _wait(p: Node3D) -> bool:
    for tick in range(12000):
        await physics_frame
        if not bool(p.get("busy")):
            return true
    return false
func _run() -> void:
    var scene := load("res://src/main.tscn").instantiate() as Node3D
    root.add_child(scene)
    await process_frame
    var p := Pool.new()
    p.name = "RealPhysicalPercentileRerollQA"
    scene.add_child(p)
    p.connect("pool_completed",Callable(self,"_done"))
    p.connect("pool_failed",Callable(self,"_failed"))
    _check(p.begin("1d100+1d4-2","normal","pair"),
        "Godot could not instantiate both real D10 percentile bodies plus D4")
    _check(await _wait(p),"Initial three-body Jolt percentile throw timed out")
    _check(physical_failure.is_empty() and latest.get("ok",false),
        "Initial real D100/D4 Jolt physical result was invalid")
    if failures>0:
        quit(1)
        return
    var bodies: Array = p.get("_active")
    _check(bodies.size()==3 and p.get("dice_spawned")==3,
        "One percentile D100 must be two actual original D10 plus the D4")
    var tens: RigidBody3D = bodies[0]
    var ones: RigidBody3D = bodies[1]
    var other: RigidBody3D = bodies[2]
    var untouched_face := int(other.get("result"))
    var first_tens := int(tens.get("result"))
    var first_ones := int(ones.get("result"))
    var initial: Dictionary = latest.duplicate(true)
    var real_digits: Array = initial["groups"][0]["percentile_source_d10_faces"][0]
    _check(int(real_digits[0])==first_tens and int(real_digits[1])==first_ones,
        "Initial source record not from genuinely settled D10 top faces")
    if FileAccess.file_exists(FILE):
        DirAccess.remove_absolute(ProjectSettings.globalize_path(FILE))
    var store := Store.new(FILE)
    _check(store.load_state().get("ok",false),"Can not open local offline QA history")
    _check(store.append_physical_result(initial).get("ok",false),
        "Initial true Jolt pair not accepted by offline store")
    for round in range(2):
        latest={}
        physical_failure=""
        _check(p.reroll_one(0,0),
            "The physically selected D100 pair could not reroll together")
        _check(await _wait(p),
            "Selected real percentile D10 bodies never finished a rethrow")
        _check(physical_failure.is_empty() and latest.get("ok",false),
            "Jolt reported a failed physical percentile reroll: "+physical_failure)
        if not latest.get("ok",false):
            break
        var retained: Array = p.get("_active")
        _check(retained.size()==3 and retained[0]==tens and
            retained[1]==ones and retained[2]==other,
            "Percentile reroll duplicated/destroyed actual Jolt source dice")
        _check(other.freeze and int(other.get("result"))==untouched_face,
            "The unrelated physical D4 moved or changed its original value")
        var history: Array = latest["groups"][0]["percentile_source_d10_faces"][0]
        _check(history.size()==round+2,
            "Full earlier original/redo paired D10 faces were not preserved")
        var current: Array = history[-1]
        _check(int(current[0])==int(tens.get("result")) and
            int(current[1])==int(ones.get("result")),
            "Recorded final tens/ones faces differ from physical rigid bodies")
        var starting: Array = history[0]
        _check(int(starting[0])==first_tens and int(starting[1])==first_ones,
            "Later reroll silently modified original D10 physical faces")
        var d100_value: int = (int(current[0])%10)*10+int(current[1])%10
        if d100_value==0:
            d100_value=100
        _check(int(latest["groups"][0]["kept_faces"][0])==d100_value and
            int(latest["total"])==d100_value+untouched_face-2,
            "Result was not recomputed from TWO genuinely observed D10 faces")
        _check(store.append_physical_result(latest).get("ok",false),
            "Independent offline persistence rejected genuine percentile reroll trace")
        print("M4_REAL_PERCENTILE_PAIR_REROLL round=%d tens=%d ones=%d result=%d" %
            [round+1,int(current[0]),int(current[1]),int(latest["total"])])
    var restarted := Store.new(FILE)
    _check(restarted.load_state().get("ok",false),
        "Full real physical source history not readable after restart")
    var saved: Array = restarted.snapshot()["history"]
    _check(saved.size()==3,
        "Initial physical outcome and two percentage rerolls must all remain")
    if not saved.is_empty():
        _check((saved[0]["groups"][0]["percentile_source_d10_faces"][0] as Array).size()==3,
            "Third independent D100 physical source pair missing from disk")
    _check(not p.reroll_one(9,9),
        "Invalid selection must not move a real D10 or fabricate a result")
    if FileAccess.file_exists(FILE):
        DirAccess.remove_absolute(ProjectSettings.globalize_path(FILE))
    print("M4_GENUINE_JOLT_PERCENTILE_REROLL checks=%d failures=%d" % [
        checks,failures])
    quit(0 if failures==0 else 1)
