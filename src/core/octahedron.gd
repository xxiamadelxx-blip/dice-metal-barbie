extends RefCounted
## Perfect regular octahedron: 6 symmetric vertices, 8 triangular faces,
## 24 proper rotations. Flat labels do not modify collision mass.
const CUBE = preload("res://src/core/cube_symmetry.gd")
const RADIUS := 0.93

static func vertices() -> PackedVector3Array:
    return PackedVector3Array([
        Vector3.RIGHT * RADIUS,
        Vector3.LEFT * RADIUS,
        Vector3.UP * RADIUS,
        Vector3.DOWN * RADIUS,
        Vector3.BACK * RADIUS,
        Vector3.FORWARD * RADIUS
    ])

static func face_indices(i: int) -> PackedInt32Array:
    ## Face i represents a unique combination of x/y/z signs.
    var ids := PackedInt32Array([
        1 if (i & 4) != 0 else 0,
        3 if (i & 2) != 0 else 2,
        5 if (i & 1) != 0 else 4
    ])
    var points := vertices()
    var a: Vector3 = points[ids[0]]
    var b: Vector3 = points[ids[1]]
    var c: Vector3 = points[ids[2]]
    if (b - a).cross(c - a).dot(a + b + c) < 0:
        var temp := ids[1]
        ids[1] = ids[2]
        ids[2] = temp
    return ids

static func face_center(i: int) -> Vector3:
    var points := vertices()
    var ids := face_indices(i)
    return (points[ids[0]] + points[ids[1]] + points[ids[2]]) / 3.0

static func face_normal(i: int) -> Vector3:
    var ids := face_indices(i)
    var points := vertices()
    var a: Vector3 = points[ids[0]]
    var b: Vector3 = points[ids[1]]
    var c: Vector3 = points[ids[2]]
    return (b - a).cross(c - a).normalized()

static func numbers() -> PackedInt32Array:
    ## Eight unique numbers, opposing faces sum to nine.
    var result := PackedInt32Array()
    result.resize(8)
    var low := 1
    for i in range(8):
        if result[i] != 0:
            continue
        result[i] = low
        result[i ^ 7] = 9 - low
        low += 1
    return result

static func rotations() -> Array[Basis]:
    return CUBE.rotations()

static func top_face(world_pose: Basis, tolerance: float = 0.02) -> int:
    var best := -2.0
    var next_best := -2.0
    var selected := -1
    for i in range(8):
        var aligned: float = (world_pose * face_normal(i)).dot(Vector3.UP)
        if aligned > best:
            next_best = best
            best = aligned
            selected = i
        elif aligned > next_best:
            next_best = aligned
    return -1 if best - next_best <= tolerance else selected

static func top_value(world_pose: Basis, tolerance: float = 0.02) -> int:
    var face := top_face(world_pose, tolerance)
    return -1 if face < 0 else numbers()[face]
