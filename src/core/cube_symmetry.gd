extends RefCounted
## M3 research spike: exact rotational symmetry group of a *perfect* cube.
## Geometric rotational symmetries preserve its physical collision shape (no mirroring).
## This can de-bias labels independently of which physical face ends up on top.
## WARNING: only valid if collision shape/inertia and launch are symmetry-equivalent.

const D6_FACE_NORMALS := [
    Vector3.UP, Vector3.DOWN, Vector3.RIGHT,
    Vector3.LEFT, Vector3.BACK, Vector3.FORWARD
]
const D6_FACE_VALUES := [1, 6, 2, 5, 3, 4]

static func rotations() -> Array[Basis]:
    var directions: Array[Vector3] = [
        Vector3.RIGHT, Vector3.LEFT, Vector3.UP,
        Vector3.DOWN, Vector3.BACK, Vector3.FORWARD
    ]
    var result: Array[Basis] = []
    for x_axis in directions:
        for y_axis in directions:
            if not is_zero_approx(x_axis.dot(y_axis)):
                continue
            var z_axis := x_axis.cross(y_axis)
            var basis := Basis(x_axis, y_axis, z_axis)
            result.append(basis)
    return result

static func pick_rotation(source: Callable = Callable()) -> Basis:
    ## Secure unbiased index 0..23, not a float modulo or random CSPRNG seed.
    var all_rotations := rotations()
    var index := preload("res://src/core/dice_rng.gd").pick(24, source) - 1
    if index < 0:
        push_error("Could not choose secure symmetry")
        return Basis.IDENTITY
    return all_rotations[index]

static func top_value(world_orientation: Basis, tolerance: float = 0.0005) -> int:
    ## Returns -1 if near a tie (cube resting on an edge / not settled).
    var best_dot := -2.0
    var next_best_dot := -2.0
    var chosen := -1
    for i in range(D6_FACE_NORMALS.size()):
        var world_normal: Vector3 = world_orientation * D6_FACE_NORMALS[i]
        var dot_up: float = world_normal.dot(Vector3.UP)
        if dot_up > best_dot:
            next_best_dot = best_dot
            best_dot = dot_up
            chosen = D6_FACE_VALUES[i]
        elif dot_up > next_best_dot:
            next_best_dot = dot_up
    if best_dot - next_best_dot <= tolerance:
        return -1
    return chosen
