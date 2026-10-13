extends RefCounted
## M3 mathematical D20 foundation. Perfect regular icosahedron: 12 vertices,
## 20 outward-wound triangular faces and 60 proper rotational symmetries.

const PHI := 1.618033988749895
const RADIUS := 0.88
const FACES = [
    [0,11,5], [0,5,1], [0,1,7], [0,7,10], [0,10,11],
    [1,5,9], [5,11,4], [11,10,2], [10,7,6], [7,1,8],
    [3,9,4], [3,4,2], [3,2,6], [3,6,8], [3,8,9],
    [4,9,5], [2,4,11], [6,2,10], [8,6,7], [9,8,1]
]

static func vertices() -> PackedVector3Array:
    var raw: Array[Vector3] = [
        Vector3(-1, PHI, 0), Vector3(1, PHI, 0),
        Vector3(-1, -PHI, 0), Vector3(1, -PHI, 0),
        Vector3(0, -1, PHI), Vector3(0, 1, PHI),
        Vector3(0, -1, -PHI), Vector3(0, 1, -PHI),
        Vector3(PHI, 0, -1), Vector3(PHI, 0, 1),
        Vector3(-PHI, 0, -1), Vector3(-PHI, 0, 1)
    ]
    var points := PackedVector3Array()
    for point in raw:
        points.append(point.normalized() * RADIUS)
    return points

static func face_normal(i: int) -> Vector3:
    var v := vertices()
    var face: Array = FACES[i]
    var a: Vector3 = v[face[0]]
    var b: Vector3 = v[face[1]]
    var c: Vector3 = v[face[2]]
    return (b - a).cross(c - a).normalized()

static func face_center(i: int) -> Vector3:
    var v := vertices()
    var face: Array = FACES[i]
    return (v[face[0]] + v[face[1]] + v[face[2]]) / 3.0

static func frame(i: int, shift: int = 0) -> Basis:
    var v := vertices()
    var f: Array = FACES[i]
    var a: Vector3 = v[f[shift % 3]]
    var b: Vector3 = v[f[(shift + 1) % 3]]
    var normal := face_normal(i)
    var x_axis := (b - a).normalized()
    var y_axis := normal.cross(x_axis)
    return Basis(x_axis, y_axis, normal)

static func proper_rotations() -> Array[Basis]:
    var all: Array[Basis] = []
    var source_inverse := frame(0).inverse()
    for face in range(FACES.size()):
        for twist in range(3):
            all.append(frame(face, twist) * source_inverse)
    return all

static func numbers() -> PackedInt32Array:
    ## Opposite faces sum to 21. Not a proprietary commercial face layout.
    var assigned := PackedInt32Array()
    assigned.resize(20)
    var low := 1
    for i in range(20):
        if assigned[i] != 0:
            continue
        var opposite := -1
        for j in range(20):
            if face_normal(i).dot(face_normal(j)) < -0.999:
                opposite = j
                break
        if opposite < 0:
            push_error("Icosahedron must have antipodal faces")
            return PackedInt32Array()
        assigned[i] = low
        assigned[opposite] = 21 - low
        low += 1
    return assigned

static func top_face(world_basis: Basis, tolerance: float = 0.002) -> int:
    var best := -2.0
    var runner := -2.0
    var selected := -1
    for i in range(20):
        var dot_up := (world_basis * face_normal(i)).dot(Vector3.UP)
        if dot_up > best:
            runner = best
            best = dot_up
            selected = i
        elif dot_up > runner:
            runner = dot_up
    if best - runner < tolerance:
        return -1
    return selected

static func top_value(world_basis: Basis, tolerance: float = 0.002) -> int:
    var face := top_face(world_basis, tolerance)
    if face < 0:
        return -1
    return numbers()[face]
