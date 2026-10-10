extends RefCounted
## Exact regular dodecahedron, dual of the verified icosahedron.
## Twenty vertices (icosahedron face centers), twelve pentagonal faces,
## sixty proper rotations. Numbers on antipodal faces sum to 13.
const Ico = preload("res://src/core/icosahedron.gd")
const RADIUS := 0.68

static func vertices() -> PackedVector3Array:
    var result := PackedVector3Array()
    for face in range(20):
        result.append(Ico.face_center(face).normalized() * RADIUS)
    return result

static func face_normal(i: int) -> Vector3:
    ## Each face corresponds to one icosahedron vertex.
    return Ico.vertices()[i].normalized()

static func face_indices(i: int) -> PackedInt32Array:
    ## The five primal faces adjacent to vertex i form the dual pentagon.
    ## Sort their centers CCW in a tangent basis, ensuring outward winding.
    var points := vertices()
    var normal := face_normal(i)
    var reference := Vector3.UP if absf(normal.y) < 0.95 else Vector3.RIGHT
    var tangent_x := normal.cross(reference).normalized()
    var tangent_y := normal.cross(tangent_x)
    var indices: Array[int] = []
    var angles: Array[float] = []
    for primal_face in range(20):
        if Ico.FACES[primal_face].has(i):
            indices.append(primal_face)
            var p: Vector3 = points[primal_face]
            angles.append(atan2(p.dot(tangent_y), p.dot(tangent_x)))
    for a in range(indices.size()):
        for b in range(a + 1, indices.size()):
            if angles[b] < angles[a]:
                var old_index := indices[a]
                var old_angle := angles[a]
                indices[a] = indices[b]
                angles[a] = angles[b]
                indices[b] = old_index
                angles[b] = old_angle
    return PackedInt32Array(indices)

static func face_center(i: int) -> Vector3:
    var points := vertices()
    var ids := face_indices(i)
    var average := Vector3.ZERO
    for index in ids:
        average += points[index]
    return average / float(ids.size())

static func numbers() -> PackedInt32Array:
    var labels := PackedInt32Array()
    labels.resize(12)
    var axis := Ico.vertices()
    var next_low := 1
    for i in range(12):
        if labels[i] != 0:
            continue
        var opposite := -1
        for j in range(12):
            if axis[i].normalized().dot(axis[j].normalized()) < -0.999:
                opposite = j
                break
        if opposite < 0:
            push_error("D12 antipodal face missing")
            return PackedInt32Array()
        labels[i] = next_low
        labels[opposite] = 13 - next_low
        next_low += 1
    return labels

static func rotations() -> Array[Basis]:
    return Ico.proper_rotations()

static func top_face(pose: Basis, tolerance: float = 0.02) -> int:
    var best := -2.0
    var second := -2.0
    var face := -1
    for i in range(12):
        var alignment: float = (pose * face_normal(i)).dot(Vector3.UP)
        if alignment > best:
            second = best
            best = alignment
            face = i
        elif alignment > second:
            second = alignment
    return -1 if best - second <= tolerance else face

static func top_value(pose: Basis, tolerance: float = 0.02) -> int:
    var face := top_face(pose, tolerance)
    return -1 if face < 0 else numbers()[face]
