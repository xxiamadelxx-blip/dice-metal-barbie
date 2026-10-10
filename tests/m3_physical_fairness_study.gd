extends SceneTree
## M3 deliberately long REAL Jolt distribution study (not a proof of fairness).
## Runs the exact playable scene and compares every physically settled kite
## with the actual displayed result, no assigned outcome or face snapping.
const Shape = preload("res://src/core/trapezohedron.gd")
const Rules = preload("res://src/core/dice_rules.gd")
const MAX_PHYSICS_TICKS := 2400
const OUT := "res://qa-evidence/m3-fairness"
var total_checks := 0
var problems: Array[String] = []
var attempts := {}
var histograms := {}
var max_settle_s := {}
var max_recovery := {}
var stream: FileAccess

func _initialize() -> void:
    call_deferred("_run")

func _count(mode: String, fallback: int) -> int:
    var key: String = "M3_FAIR_" + mode
    var raw: String = OS.get_environment(key)
    if raw.is_valid_int():
        return clampi(int(raw), 1, 2000)
    return fallback

func _write_progress(note: String) -> void:
    if stream != null:
        stream.store_string(note + "\n")
        stream.flush()

func _verify(condition: bool, description: String) -> bool:
    total_checks += 1
    if not condition:
        problems.append(description)
        push_error(description)
    return condition

func _await_real_rest(bodies: Array[RigidBody3D]) -> bool:
    for tick in range(MAX_PHYSICS_TICKS):
        await physics_frame
        var running := false
        for body in bodies:
            if not is_instance_valid(body) or bool(body.get("rolling")):
                running = true
        if not running:
            return true
    return false

func _analyze(mode: String, count: int) -> Dictionary:
    var frequency: Dictionary = histograms[mode]
    var grouped: Array[int] = []
    for i in range(10):
        grouped.append(0)
    for value in frequency.keys():
        var number := int(value)
        var bucket: int = (number - 1) if mode == "D10" else (number - 1) / 10
        grouped[bucket] += int(frequency[value])
    var expectation := float(count) / 10.0
    var chi_square := 0.0
    for observed in grouped:
        chi_square += pow(float(observed) - expectation, 2.0) / expectation
    # 9 degrees of freedom: conservative, exploratory cutoff about p<0.001.
    # Even a PASS cannot certify physical fairness or all 100 categories.
    return {"bins":grouped,"expected_per_bin":expectation,
        "chi_square_df9":chi_square,"coarse_bias_alert":count >= 100 and chi_square > 30.0,
        "statistical_scope":"ten grouped output bands; not individual D100 face proof"}

func _save_report() -> void:
    var out := {"source":"REAL_PRODUCTION_GODOT_JOLT",
        "purpose":"bounded reliability + exploratory coarse output-bias screening",
        "not_proven":"100-face equal probabilities, independence, on-device FPS",
        "attempts":attempts,"histograms":histograms,
        "max_settle_seconds":max_settle_s,
        "max_edge_recoveries":max_recovery,"checks":total_checks,
        "errors":problems}
    for mode in histograms:
        var c: int = int(attempts[mode]["completed"])
        if c > 0:
            out["stats_"+mode] = _analyze(mode,c)
    var f := FileAccess.open(OUT + "/study-report.json",FileAccess.WRITE)
    if f != null:
        f.store_string(JSON.stringify(out,"  ") + "\n")
        f.close()

func _run() -> void:
    DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
    stream = FileAccess.open(OUT + "/every-physical-throw.jsonl",FileAccess.WRITE)
    var scene := load("res://src/main.tscn").instantiate() as Node3D
    if not _verify(scene != null,"Actual game scene could not load"):
        _save_report()
        quit(1)
        return
    root.add_child(scene)
    await process_frame
    var required := {"D10":_count("D10",150),
        "D100":_count("D100",200),
        "D100_PAIR":_count("D100_PAIR",100)}
    for mode in ["D10","D100","D100_PAIR"]:
        var wanted: int = required[mode]
        histograms[mode] = {}
        attempts[mode] = {"requested":wanted,"attempted":0,"completed":0}
        max_settle_s[mode] = 0.0
        max_recovery[mode] = 0
        for run in range(wanted):
            if mode == "D10":
                scene.call("_throw_physical_d10")
            elif mode == "D100":
                scene.call("_throw_physical_d100")
            else:
                scene.call("_throw_percentile_d100")
            attempts[mode]["attempted"] = run+1
            await physics_frame
            var bodies: Array[RigidBody3D] = []
            if mode == "D100_PAIR":
                var pair := scene.get_node_or_null("PhysicalD100Percentile") as Node3D
                var current: Node3D = scene.get("active_percentile") as Node3D
                if not _verify(pair != null and pair == current,
                    "%s run %d observed stale percentiles parent" % [mode,run]):
                    break
                var a := pair.get_node_or_null("TensD10") as RigidBody3D
                var b := pair.get_node_or_null("OnesD10") as RigidBody3D
                if a != null:
                    bodies.append(a)
                if b != null:
                    bodies.append(b)
            else:
                var s := 10 if mode == "D10" else 100
                var body := scene.get_node_or_null("PhysicalD%d" % s) as RigidBody3D
                if body != null:
                    bodies.append(body)
            var expected_bodies := 2 if mode == "D100_PAIR" else 1
            if not _verify(bodies.size() == expected_bodies,
                "%s run %d missing or duplicate Jolt bodies" % [mode,run]):
                break
            var finished: bool = await _await_real_rest(bodies)
            if not _verify(finished,
                "%s run %d never completed physically" % [mode,run]):
                break
            var valid := true
            var face_values: Array[int] = []
            var longest := 0.0
            var recoveries := 0
            for body in bodies:
                var side_count := 100 if mode == "D100" else 10
                var number: int = Shape.top_value(side_count,
                    body.global_transform.basis.orthonormalized())
                face_values.append(number)
                var match_face := number >= 1 and number <= side_count and (
                    number == int(body.get("result")) and body.sleeping and
                    str(body.get("failure")) == "")
                valid = _verify(match_face,
                    "%s run %d visible face differs from sleeping body" % [mode,run]) and valid
                longest = maxf(longest,float(body.get("elapsed")))
                recoveries = maxi(recoveries,int(body.get("edge_recovery_count")))
            var result: int = face_values[0]
            if mode == "D100_PAIR":
                result = Rules.percentile((face_values[0] % 10)*10,face_values[1] % 10)
            valid = _verify(result == int(scene.get("last_result")),
                "%s run %d HUD differs from actual physical result" % [mode,run]) and valid
            _write_progress(JSON.stringify({"mode":mode,"trial":run,
                "visible_faces":face_values,"result":result,
                "elapsed_s":longest,"recoveries":recoveries,"valid":valid}))
            if not valid:
                break
            attempts[mode]["completed"] = run+1
            var hs: Dictionary = histograms[mode]
            var key := str(result)
            hs[key] = int(hs.get(key,0)) + 1
            max_settle_s[mode] = maxf(float(max_settle_s[mode]),longest)
            max_recovery[mode] = maxi(int(max_recovery[mode]),recoveries)
            if run % 20 == 19:
                print("M3_FAIRNESS_PROGRESS %s %d/%d" % [mode,run+1,wanted])
                _save_report()
            await process_frame
        if int(attempts[mode]["completed"]) != wanted:
            _verify(false,"%s stopped after %d/%d physical throws" %
                [mode,int(attempts[mode]["completed"]),wanted])
        else:
            var stat := _analyze(mode,wanted)
            # An alert is not the same as proof of bias. Preserve all
            # individual outcome logs for an independent check.
            if bool(stat["coarse_bias_alert"]):
                _verify(false,"%s coarse output bias alert: chi-square=%s" %
                    [mode,str(stat["chi_square_df9"])])
        _save_report()
        if problems.size() > 0:
            break
    print("M3_FAIRNESS_END: %d checks, %d failures" % [total_checks,problems.size()])
    _save_report()
    if stream != null:
        stream.close()
    quit(0 if problems.is_empty() else 1)
