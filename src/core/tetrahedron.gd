extends RefCounted
## Regular tetrahedral D4. The winning number is marked three times on
## the sloping faces adjacent to the uppermost vertex (apex-reading D4).
## A conventional tetrahedron NEVER rests with a horizontal upper face.
const CubeGroup = preload("res://src/core/cube_symmetry.gd")
const RADIUS := 0.98

static func vertices() -> PackedVector3Array:
    var points := PackedVector3Array()
    for direction in [
        Vector3(1, 1, 1), Vector3(-1, -1, 1),
        Vector3(-1, 1, -1), Vector3(1, -1, -1)
    ]:
        points.append(direction.normalized() * RADIUS)
    return points

static func face_indices(opposite_vertex: int) -> PackedInt32Array:
    var indices := PackedInt32Array()
    for i in range(4):
        if i != opposite_vertex:
            indices.append(i)
    var points := vertices()
    var a: Vector3 = points[indices[0]]
    var b: Vector3 = points[indices[1]]
    var c: Vector3 = points[indices[2]]
    if (b - a).cross(c - a).dot(a + b + c) < 0.0:
        var t := indices[1]
        indices[1] = indices[2]
        indices[2] = t
    return indices

static func face_center(opposite_vertex: int) -> Vector3:
    var ids := face_indices(opposite_vertex)
    var p := vertices()
    return (p[ids[0]] + p[ids[1]] + p[ids[2]]) / 3.0

static func face_normal(opposite_vertex: int) -> Vector3:
    var ids := face_indices(opposite_vertex)
    var p := vertices()
    return (p[ids[1]] - p[ids[0]]).cross(p[ids[2]] - p[ids[0]]).normalized()

static func printed_position(apex_vertex: int, face_opposite_vertex: int) -> Vector3:
    ## For each apex, the three adjacent sloping faces share its printed value.
    ## Put glyphs IN the face triangle, not at the impossible top horizontal face.
    if apex_vertex == face_opposite_vertex:
        return Vector3.ZERO
    var p := vertices()
    return p[apex_vertex].lerp(face_center(face_opposite_vertex), 0.48) + face_normal(face_opposite_vertex) * 0.003

static func rotations() -> Array[Basis]:
    ## Index-2 subgroup of the cube group. Proper symmetry group has order 12.
    var all: Array[Basis] = []
    var p := vertices()
    for b in CubeGroup.rotations():
        var preserve := true
        for v in p:
            var matches := false
            for q in p:
                if (b * v).distance_to(q) < 0.0001:
                    matches = true
                    break
            if not matches:
                preserve = false
                break
        if preserve:
            all.append(b)
    return all

static func top_vertex(pose: Basis, tolerance: float = 0.02) -> int:
    var best := -2.0
    var second := -2.0
    var winning := -1
    for i in range(4):
        var alignment: float = (pose * vertices()[i].normalized()).dot(Vector3.UP)
        if alignment > best:
            second = best
            best = alignment
            winning = i
        elif alignment > second:
            second = alignment
    return -1 if best - second <= tolerance else winning

static func top_value(pose: Basis, tolerance: float = 0.02) -> int:
    var vertex := top_vertex(pose, tolerance)
    return -1 if vertex < 0 else vertex + 1
