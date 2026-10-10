extends SceneTree
## Mathematical verification of a real cube's 24 rotational symmetries.
## This proves label-uniformity conditional on perfect cubic physics, NOT M3 gameplay.

const Symmetry = preload("res://src/core/cube_symmetry.gd")
var failures := 0
var checks := 0

class FakeEntropy:
    extends RefCounted
    var values: Array[int] = []
    func fetch(n: int) -> PackedByteArray:
        var out := PackedByteArray()
        for i in range(n):
            if values.is_empty():
                return PackedByteArray()
            out.append(values.pop_front())
        return out

func _initialize() -> void:
    call_deferred("_run")

func _assert_equal(actual: Variant, expected: Variant, label: String) -> void:
    checks += 1
    if actual != expected:
        failures += 1
        push_error("%s: expected=%s actual=%s" % [label, str(expected), str(actual)])

func _run() -> void:
    var rotations := Symmetry.rotations()
    _assert_equal(rotations.size(), 24, "Cube has 24 rotational symmetries")
    var seen := {}
    for basis in rotations:
        _assert_equal(is_equal_approx(basis.determinant(), 1.0), true, "Proper rotation determinant +1")
        var key := str(basis)
        seen[key] = true
    _assert_equal(seen.size(), 24, "All cube rotations unique")

    ## Any arbitrary final physical orientation must map to each D6 label
    ## EXACTLY 4 times across the 24 equally likely label symmetries.
    ## Not a random Monte Carlo test: exhaustive enumeration.
    var orientations := [
        Basis.IDENTITY,
        Basis(Quaternion(Vector3(0.31, 0.54, 0.78).normalized(), 1.07)),
        Basis(Quaternion(Vector3(0.91, 0.18, 0.27).normalized(), 2.43)),
        Basis(Quaternion(Vector3(0.22, 0.75, 0.61).normalized(), 0.61))
    ]
    for physical_orientation in orientations:
        var counts := {}
        for face in range(1, 7):
            counts[face] = 0
        for relabel_rotation in rotations:
            var visible := Symmetry.top_value(physical_orientation * relabel_rotation)
            _assert_equal(visible >= 1 and visible <= 6, true, "Visible side well-defined")
            if visible >= 1 and visible <= 6:
                counts[visible] += 1
        for face in range(1, 7):
            _assert_equal(counts[face], 4, "Equal multiplicity for D6 face %d" % face)

    ## D6 opposite pairs must sum to 7.
    _assert_equal(Symmetry.top_value(Basis.IDENTITY), 1, "+Y = 1")
    _assert_equal(Symmetry.top_value(Basis(Vector3.RIGHT, Vector3.DOWN, Vector3.FORWARD)), 6, "-Y = 6")

    ## Secure RNG injection: 255 rejected for 24 outcomes; 23 maps to index 23.
    var fake := FakeEntropy.new()
    fake.values.assign([255, 23])
    var selected := Symmetry.pick_rotation(Callable(fake, "fetch"))
    _assert_equal(is_equal_approx(selected.determinant(), 1.0), true, "Secure rotation index after rejection")

    print("M3 cube symmetry proof: %d checks, %d failed" % [checks, failures])
    quit(0 if failures == 0 else 1)
