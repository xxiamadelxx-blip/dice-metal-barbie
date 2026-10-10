extends SceneTree
## Exhaustive deterministic mapping of all 100 combinations of two real
## D10 face labels. Actual independent Jolt bodies tested separately.
const ShapeMath = preload("res://src/core/trapezohedron.gd")
const DiceRules = preload("res://src/core/dice_rules.gd")
var checked := 0
var failed := 0
func _initialize() -> void:
    call_deferred("_run")
func _expect(ok: bool, what: String) -> void:
    checked += 1
    if not ok:
        failed += 1
        push_error(what)
func _run() -> void:
    var values := ShapeMath.numbers(10)
    _expect(values.size() == 10, "Physical D10 must have exactly 10 labels")
    var seen := {}
    for ten in values:
        for one in values:
            var td: int = int(ten) % 10
            var od: int = int(one) % 10
            var result: int = DiceRules.percentile(td * 10, od)
            var expected: int = 100 if td == 0 and od == 0 else td * 10 + od
            _expect(result == expected, "D100 physical digit mapping failed")
            _expect(result >= 1 and result <= 100, "D100 invalid result")
            _expect(not seen.has(result), "D100 duplicate combination result")
            seen[result] = true
    _expect(seen.size() == 100, "Not all D100 results reachable")
    for face in range(1,101):
        _expect(seen.has(face), "D100 missing result %d" % face)
    print("M3 pair mapping: %d checks, %d errors" % [checked,failed])
    quit(0 if failed == 0 else 1)
