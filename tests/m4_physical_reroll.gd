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
    var last_verified := observed.duplicate(true)
    _check(not pool.call("reroll_one",15,15),
        "Nonexistent die selection must not invent physical outcomes")
    _check(pool.get("last_result")==last_verified,
        "Invalid reroll changed last valid physical result")
    print("M4 real selected-Jolt reroll: %d checks, %d failures" % [checks,failures])
    quit(0 if failures==0 else 1)
