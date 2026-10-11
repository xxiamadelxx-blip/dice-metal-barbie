extends SceneTree
## Test-only evaluator fixtures: NEVER claimed as real Jolt throws.
const Stats = preload("res://src/core/roll_statistics.gd")
const Formula = preload("res://src/core/roll_formula.gd")
var checks := 0
var fails := 0
func _initialize() -> void:
    call_deferred("_run")
func _check(ok: bool, reason: String) -> void:
    checks += 1
    if not ok:
        fails += 1
        push_error(reason)
func _run() -> void:
    var a: Dictionary = Formula.evaluate(Formula.parse("1d20+2"),[[20]])
    var b: Dictionary = Formula.evaluate(Formula.parse("1d20+2"),[[1]])
    var c: Dictionary = Formula.evaluate(Formula.parse("1d100"),
        [[{"states":[[4,3],[4,10]]}]])
    var d: Dictionary = Formula.evaluate(Formula.parse("2d6-5"),[[2,3]])
    _check(bool(a.get("ok",false)) and bool(b.get("ok",false)) and
        bool(c.get("ok",false)) and bool(d.get("ok",false)),"Fixture evaluator failed")
    var entries: Array = [a,b,c,d]
    var original := entries.duplicate(true)
    var s: Dictionary = Stats.summarize(entries)
    _check(int(s["records"])==4 and int(s["total_sum"])==65,"Wrong receipt count/sum")
    _check(is_equal_approx(float(s["average"]),16.25),"Wrong signed mean")
    _check(int(s["minimum"])==0 and int(s["maximum"])==40,"Wrong min/max")
    _check(int(s["crit20"])==1 and int(s["crit1"])==1,"Wrong natural D20 critical counts")
    _check(int(s["reroll_receipts"])==1,"Paired D100 reroll receipt not counted exactly once")
    _check(Stats.describe(s).contains("не проверка равномерности"),"Missing fairness disclaimer")
    _check(int(Stats.summarize([])["records"])==0,"Empty history failed")
    var hostile: Array = entries.duplicate(true)
    hostile.append({"ok":true,"source":"synthetic","total":999,"groups":[{}]})
    hostile.append({"ok":true,"source":"actual_physical_faces_required","total":"??","groups":[{}]})
    # Independent Qwen 7B #38152226265 identified int(float) truncation as
    # a possible bug. This *adversarial* regression proves fractional input
    # gets REJECTED by the explicit round-trip float equality guard; it is
    # not rounded down into a fictitious signed physical result.
    var fractional_positive: Dictionary = a.duplicate(true)
    fractional_positive["total"]=12.99
    var fractional_negative: Dictionary = b.duplicate(true)
    fractional_negative["total"]=-12.99
    hostile.append(fractional_positive)
    hostile.append(fractional_negative)
    _check(int(Stats.summarize(hostile)["records"])==4,
        "Reject forged, nonnumeric, positive and negative fractional dice totals")
    _check(int(Stats.summarize(hostile)["total_sum"])==65,
        "Fractional totals were silently truncated into saved sums")
    _check(entries==original,"Read-only metrics mutated source history")
    print("M4_OFFLINE_RECEIPT_STATISTICS checks=%d failures=%d" % [checks,fails])
    quit(0 if fails==0 else 1)
