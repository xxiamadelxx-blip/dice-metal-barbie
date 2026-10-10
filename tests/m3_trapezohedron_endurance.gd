extends SceneTree
## M3 bounded REAL Jolt endurance. This is not a high-power proof of fair
## physical outcome distribution. Each result is measured from a true
## sleeping convex body with its top kite face, not pre-selected RNG.
const ShapeMath = preload("res://src/core/trapezohedron.gd")
const Rules = preload("res://src/core/dice_rules.gd")
const TRIALS_D10 := 20
const TRIALS_D100 := 12
const TRIALS_D100_PAIR := 16
const MAX_TICKS := 2400
var checks := 0
var failures := 0
var problems: Array[String] = []
var samples := {}
var tries := {}

func _initialize() -> void:
    call_deferred("_run")

func _expect(ok: bool, detail: String) -> void:
    checks += 1
    if not ok:
        failures += 1
        problems.append(detail)
        push_error(detail)

func _await_physics(dice: Array[RigidBody3D]) -> bool:
    for tick in range(MAX_TICKS):
        await physics_frame
        var settled := true
        for die in dice:
            if not is_instance_valid(die) or bool(die.get("rolling")):
                settled = false
        if settled:
            return true
    return false

func _run() -> void:
    var scene := load("res://src/main.tscn").instantiate() as Node3D
    _expect(scene != null, "Cannot load authentic 3D Jolt game scene")
    if scene == null:
        quit(1)
        return
    root.add_child(scene)
    await process_frame
    for mode in ["D10", "D100", "D100_PAIR"]:
        var size := 10 if mode == "D10" else 100
        var loops := TRIALS_D10 if mode == "D10" else (
            TRIALS_D100 if mode == "D100" else TRIALS_D100_PAIR)
        samples[mode] = {}
        tries[mode] = {"attempted":0,"completed":0,"failed":0,
            "max_recoveries":0,"max_settle_s":0.0}
        for trial in range(loops):
            # Keep UI and physics unchanged between tests. The only trial
            # input is pressing the existing real-game throw action.
            if mode == "D10":
                scene.call("_throw_physical_d10")
            elif mode == "D100":
                scene.call("_throw_physical_d100")
            else:
                scene.call("_throw_percentile_d100")
            tries[mode]["attempted"] = trial + 1
            await physics_frame
            var dice: Array[RigidBody3D] = []
            if mode == "D100_PAIR":
                var parent := scene.get_node_or_null("PhysicalD100Percentile")
                if parent != null:
                    for child_name in ["TensD10", "OnesD10"]:
                        var child := parent.get_node_or_null(child_name) as RigidBody3D
                        if child != null:
                            dice.append(child)
                _expect(dice.size() == 2,
                    "%s trial %d needs exactly two independent Jolt D10" % [mode,trial])
            else:
                var die := scene.get_node_or_null("PhysicalD%d" % size) as RigidBody3D
                if die != null:
                    dice.append(die)
                _expect(dice.size() == 1,
                    "%s trial %d has no actual Jolt body" % [mode,trial])
            if dice.size() != (2 if mode == "D100_PAIR" else 1):
                tries[mode]["failed"] = int(tries[mode]["failed"]) + 1
                break
            var finished := await _await_physics(dice)
            _expect(finished, "%s trial %d Jolt did not stop" % [mode,trial])
            if not finished:
                tries[mode]["failed"] = int(tries[mode]["failed"]) + 1
                break
            var valid := true
            var faces: Array[int] = []
            var max_recovery := 0
            var max_elapsed := 0.0
            for die in dice:
                var die_sides := 10 if mode != "D100" else 100
                var face_value: int = ShapeMath.top_value(die_sides,
                    die.global_transform.basis.orthonormalized())
                faces.append(face_value)
                var good := str(die.get("failure")) == "" and die.sleeping and (
                    face_value >= 1 and face_value <= die_sides and
                    face_value == int(die.get("result")))
                _expect(good, "%s trial %d body result/true face failed" % [mode,trial])
                valid = valid and good
                max_recovery = maxi(max_recovery, int(die.get("edge_recovery_count")))
                max_elapsed = maxf(max_elapsed, float(die.get("elapsed")))
            var result := faces[0]
            if mode == "D100_PAIR" and faces.size() == 2:
                result = Rules.percentile((faces[0] % 10)*10, faces[1] % 10)
            var agrees := result == int(scene.get("last_result")) and (
                result >= 1 and result <= size)
            _expect(agrees, "%s trial %d HUD/physical outcome mismatch" % [mode,trial])
            valid = valid and agrees
            if not valid:
                tries[mode]["failed"] = int(tries[mode]["failed"]) + 1
                break
            tries[mode]["completed"] = int(tries[mode]["completed"]) + 1
            tries[mode]["max_recoveries"] = maxi(int(tries[mode]["max_recoveries"]),
                max_recovery)
            tries[mode]["max_settle_s"] = maxf(float(tries[mode]["max_settle_s"]),
                max_elapsed)
            var histogram: Dictionary = samples[mode]
            var key := str(result)
            histogram[key] = int(histogram.get(key,0)) + 1
            if trial % 4 == 3:
                print("M3_STRESS %s completed %d/%d, latest Jolt=%d, "
                    % [mode,trial+1,loops,result])
            await process_frame
        _expect(int(tries[mode]["completed"]) == loops,
            "%s completed %d/%d physical throws" % [
                mode,int(tries[mode]["completed"]),loops])
        # Sanity only, not a distribution fairness claim.
        _expect((samples[mode] as Dictionary).size() > 1,
            "%s suspiciously identical physical results in all throws" % mode)
        if failures > 0:
            break
    var result_doc := {"provenance":"REAL_HEADLESS_JOLT_WITH_GAME_SCENE",
        "sampling_note":"Small bounded stress is reliability/face check; NOT a statistical fairness proof",
        "results":tries,"histograms":samples,"checks":checks,"failures":failures,
        "problems":problems}
    var dir := ProjectSettings.globalize_path("res://qa-evidence/m3-stress")
    DirAccess.make_dir_recursive_absolute(dir)
    var f := FileAccess.open(dir.path_join("endurance.json"),FileAccess.WRITE)
    if f != null:
        f.store_string(JSON.stringify(result_doc,"  ")+"\n")
        f.close()
    print("M3_ENDURANCE physical results: %s" % JSON.stringify(result_doc))
    quit(0 if failures == 0 else 1)
