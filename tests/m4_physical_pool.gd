extends SceneTree
## M4 real production-shape Jolt integration, NOT formula-math mock values.
## Every fixture requires genuine sleeping bodies and completed face signals.
const Pool = preload("res://src/core/physical_roll_pool.gd")
var checks := 0
var failures := 0
var completed: Dictionary = {}
var error := ""

func _initialize() -> void:
    call_deferred("_run")

func _check(ok: bool, what: String) -> void:
    checks += 1
    if not ok:
        failures += 1
        push_error(what)

func _on_completed(outcome: Dictionary) -> void:
    completed = outcome

func _on_failed(reason: String) -> void:
    error = reason

func _wait_for(pool: Node3D) -> bool:
    for tick in range(16000):
        await physics_frame
        if not pool.get("busy"):
            return true
    return false

func _run() -> void:
    var scene := load("res://src/main.tscn").instantiate() as Node3D
    root.add_child(scene)
    await process_frame
    var pool := Pool.new()
    pool.name = "M4RealPhysicalPool"
    scene.add_child(pool)
    pool.connect("pool_completed",Callable(self,"_on_completed"))
    pool.connect("pool_failed",Callable(self,"_on_failed"))
    for fixture in [
        {"formula":"2d6+1d20-3","mode":"normal","hundred":"pair",
            "expected_bodies":3,"expected_groups":2},
        {"formula":"1d100+1d4-2","mode":"normal","hundred":"pair",
            "expected_bodies":3,"expected_groups":2},
        {"formula":"1d20+2","mode":"advantage","hundred":"pair",
            "expected_bodies":2,"expected_groups":1},
        {"formula":"3d6+1d20+2","mode":"normal","hundred":"pair",
            "expected_bodies":4,"expected_groups":2},
        {"formula":"2d8+1d12+1d4","mode":"normal","hundred":"pair",
            "expected_bodies":4,"expected_groups":3},
        {"formula":"2d6+1d20-3","mode":"normal","hundred":"pair",
            "expected_bodies":3,"expected_groups":2},
        {"formula":"8d6","mode":"normal","hundred":"pair",
            "expected_bodies":8,"expected_groups":1},
        {"formula":"2d100+1d4","mode":"normal","hundred":"pair",
            "expected_bodies":5,"expected_groups":2},
    ]:
        completed = {}
        error = ""
        var old_count := int(pool.get("dice_spawned"))
        var ok: bool = pool.call("begin",fixture["formula"],fixture["mode"],
            fixture["hundred"],-1)
        _check(ok,"M4 physical pool refused valid formula "+fixture["formula"])
        if not ok:
            break
        var ended := await _wait_for(pool)
        _check(ended,"M4 physical pool timed out "+fixture["formula"])
        _check(error.is_empty(),"M4 Jolt body failed "+error)
        _check(bool(completed.get("ok",false)),
            "M4 physical pool emitted no real result "+fixture["formula"])
        if not ended or not error.is_empty() or not bool(completed.get("ok",false)):
            break
        _check((completed["groups"] as Array).size() == fixture["expected_groups"],
            "M4 physical pool lost a group")
        var count := 0
        var bodies_count := 0
        var physical_total := int(completed["modifier"])
        for group in completed["groups"]:
            var source: Array = group["attempts"]
            count += source.size()
            bodies_count += source.size() * (2 if int(group["sides"]) == 100 else 1)
            var subtotal := 0
            for face_series in source:
                _check(face_series.size() == 1,
                    "M4 physical pool wrote an invented reroll")
            for face in group["kept_faces"]:
                subtotal += int(face)
            physical_total += subtotal*int(group["sign"])
            _check(subtotal*int(group["sign"]) == group["subtotal"],
                "M4 source-group subtotal was altered")
            if int(group["sides"]) == 100:
                var observed_pairs: Array = group["percentile_source_d10_faces"]
                var all_sources_preserved := observed_pairs.size() == source.size()
                for true_pair in observed_pairs:
                    if typeof(true_pair) != TYPE_ARRAY:
                        all_sources_preserved = false
                        continue
                    var digits: Array = true_pair
                    if digits.size() != 2:
                        all_sources_preserved = false
                        continue
                    if not (int(digits[0]) >= 1 and int(digits[0]) <= 10 and
                            int(digits[1]) >= 1 and int(digits[1]) <= 10):
                        all_sources_preserved = false
                _check(all_sources_preserved,
                    "M4 each physical D100 needs its OWN two real D10 top faces")
        _check(bodies_count == fixture["expected_bodies"],
            "M4 did not physically throw every requested Jolt body")
        _check(completed["total"]==physical_total,
            "M4 total diverges from actual kept physical faces")
        _check(pool.get("last_physical_error") == "",
            "M4 physical integration recorded a Jolt failure")
        var bodies: Array = pool.get("_active")
        _check(bodies.size()==fixture["expected_bodies"],
            "M4 dropped earlier real Jolt dice from the visible table")
        _check(int(pool.get("dice_spawned")) == bodies.size(),
            "M4 actual bodies count diverges from source evidence")
        _check(int(pool.get("physics_completed")) == bodies.size(),
            "M4 did not receive one actual Jolt completion per physical die")
        _check(int(pool.get("peak_simultaneously_rolling")) >= 2,
            "M4 did not physically roll 2+ rigid bodies in the SAME physics tick")
        _check(bool(completed.get("all_source_bodies_remain_visible",false)),
            "M4 wrongly claimed all source dice visible")
        var distinct: Dictionary = {}
        for body in bodies:
            var rigid := body as RigidBody3D
            _check(rigid != null and is_instance_valid(rigid) and rigid.get_parent()==pool,
                "M4 source die was removed from the table before result")
            if rigid != null:
                _check(rigid.sleeping and not bool(rigid.get("rolling")),
                    "M4 presented a numeric result before all Jolt bodies slept")
                distinct[rigid.get_instance_id()] = true
        _check(distinct.size()==bodies.size(),
            "M4 attached the same rigid body twice instead of unique dice")
        _check(int(completed.get("physical_bodies",-1))==bodies.size(),
            "Physical body count missing in recorded composite receipt")
        print("M4_REAL_JOLT %s total=%d actual_bodies=%d" %
            [fixture["formula"],int(completed["total"]),bodies_count])
        await process_frame
    print("M4 real physical pool: %d checks, %d failures" % [checks,failures])
    quit(0 if failures == 0 else 1)
