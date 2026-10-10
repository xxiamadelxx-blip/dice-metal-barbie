extends SceneTree
## Run: godot --headless --path . --script res://tests/smoke.gd

const Rng = preload("res://src/core/dice_rng.gd")
const Rules = preload("res://src/core/dice_rules.gd")
var passed := 0
var failed := 0

class FakeEntropy:
    extends RefCounted
    var values: Array[int] = []
    func fetch(n: int) -> PackedByteArray:
        var bytes := PackedByteArray()
        for i in range(n):
            if values.is_empty():
                return PackedByteArray()
            bytes.append(values.pop_front())
        return bytes

func _initialize() -> void:
    call_deferred("_run")

func _test(actual: Variant, expected: Variant, label: String) -> void:
    if actual == expected:
        passed += 1
    else:
        failed += 1
        push_error("%s: got %s, expected %s" % [label, str(actual), str(expected)])

func _run() -> void:
    var fake := FakeEntropy.new()
    fake.values.assign([0, 251, 255, 13])
    _test(Rng.pick(6, Callable(fake, "fetch")), 1, "D6 minimum")
    _test(Rng.pick(6, Callable(fake, "fetch")), 6, "D6 maximum")
    _test(Rng.pick(6, Callable(fake, "fetch")), 2, "D6 rejection then 13")
    var secure_result := Rng.pick(20)
    _test(secure_result >= 1 and secure_result <= 20, true, "secure D20 range")
    _test(Rules.percentile(0, 0), 100, "D100 00+0")
    _test(Rules.percentile(90, 9), 99, "D100 90+9")
    _test(Rules.percentile(30, 4), 34, "D100 30+4")
    _test(Rules.percentile(10, 10), -1, "invalid percentile")
    _test(Rules.choose_advantage(12, 19), 19, "advantage")
    _test(Rules.choose_advantage(12, 19, true), 12, "disadvantage")
    _test(Rules.critical_d20(1), "failure", "natural 1")
    _test(Rules.critical_d20(20), "success", "natural 20")
    _test(Rules.critical_d20(19), "none", "no critical")
    _test(Rules.sum_rolls([2, 6, 3], 4), 15, "sum + modifier")
    print("M2 tests: %d passed, %d failed" % [passed, failed])
    quit(0 if failed == 0 else 1)

