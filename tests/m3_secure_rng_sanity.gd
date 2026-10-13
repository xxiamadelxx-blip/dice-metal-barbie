extends SceneTree
## Statistical SANITY of the SECURE INPUT RNG, not physical-die fairness.
## Samples genuinely call the same Crypto rejection-sampling source as game.
const DiceRng = preload("res://src/core/dice_rng.gd")
const DRAWS := 12000
var failures := 0

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    for sides in [10,100]:
        var counts := PackedInt32Array()
        counts.resize(sides + 1)
        for i in range(DRAWS):
            var face: int = DiceRng.pick(sides)
            if face < 1 or face > sides:
                failures += 1
                push_error("Secure random draw outside D%d: %d" % [sides,face])
                break
            counts[face] += 1
        var expected := float(DRAWS) / float(sides)
        var sigma := sqrt(expected * (1.0 - 1.0 / float(sides)))
        var worst_deviation := 0.0
        var min_count := DRAWS
        var max_count := 0
        for face in range(1,sides+1):
            var c: int = counts[face]
            min_count = mini(min_count,c)
            max_count = maxi(max_count,c)
            worst_deviation = maxf(worst_deviation,absf(float(c)-expected))
        # Very conservative 7 sigma + rounding: catches gross bugs but
        # almost never rejects a statistically correct Crypto generator.
        if worst_deviation > 7.0 * sigma + 5.0:
            failures += 1
            push_error("D%d secure-source frequency anomaly: dev=%.1f" %
                [sides,worst_deviation])
        print("M3_SECURE_RNG sides=%d n=%d expected=%.2f min=%d max=%d "
            % [sides,DRAWS,expected,min_count,max_count] +
            "worst_deviation=%.2f sigma=%.2f (not physical fairness proof)" %
            [worst_deviation,sigma])
    quit(0 if failures == 0 else 1)
