extends RefCounted
## Dual of a regular n-gonal antiprism: 2*n congruent kite faces.
## n=5 => 10 faces / 12 vertices; n=50 => 100 faces / 102 vertices.
## This is the actual Jolt collision hull, not a cosmetic approximation.
const HEIGHT := 0.70
const RADIUS := 0.98

static func _n(sides: int) -> int:
    return sides / 2 if sides == 10 or sides == 100 else 0

static func _scale(sides: int) -> float:
    var n := _n(sides)
    if n == 0:
        return 0.0
    var phi := PI / float(n)
    var c := 0.5 * (1.0 + cos(phi))
    var slope := (1.0 - cos(phi)) / (2.0 * HEIGHT)
    return RADIUS / maxf(1.0 / HEIGHT, sqrt(1.0 + slope * slope) / c)

static func vertices(sides: int) -> PackedVector3Array:
    var n := _n(sides)
    var points := PackedVector3Array()
    if n == 0:
        return points
    var phi := PI / float(n)
    var c := 0.5 * (1.0 + cos(phi))
    var slope := (1.0 - cos(phi)) / (2.0 * HEIGHT)
    var scale := _scale(sides)
    points.append(Vector3(0, 1.0 / HEIGHT, 0) * scale)
    points.append(Vector3(0, -1.0 / HEIGHT, 0) * scale)
    for i in range(n):
        var upper_angle := TAU * float(i) / float(n) + phi
        var lower_angle := upper_angle + phi
        points.append(Vector3(cos(upper_angle) / c, slope / c, sin(upper_angle) / c) * scale)
        points.append(Vector3(cos(lower_angle) / c, -slope / c, sin(lower_angle) / c) * scale)
    return points

static func _primal_vertex(sides: int, face: int) -> Vector3:
    var n := _n(sides)
    var ring := face % n
    var upper := face < n
    var angle := TAU * float(ring) / float(n) + (0.0 if upper else PI / float(n))
    return Vector3(cos(angle), HEIGHT if upper else -HEIGHT, sin(angle))

static func face_normal(sides: int, face: int) -> Vector3:
    if _n(sides) == 0 or face < 0 or face >= sides:
        return Vector3.ZERO
    return _primal_vertex(sides, face).normalized()

static func face_indices(sides: int, face: int) -> PackedInt32Array:
    if _n(sides) == 0 or face < 0 or face >= sides:
        return PackedInt32Array()
    var points := vertices(sides)
    var primal := _primal_vertex(sides, face)
    var normal := primal.normalized()
    var center := Vector3.ZERO
    var indices: Array[int] = []
    var target := _scale(sides)
    for index in range(points.size()):
        if absf(points[index].dot(primal) - target) < 0.0001:
            indices.append(index)
            center += points[index]
    if indices.size() != 4:
        push_error("D%d face %d is not a real planar kite: %d vertices" % [sides, face, indices.size()])
        return PackedInt32Array()
    center /= 4.0
    var reference := Vector3.UP if absf(normal.y) < 0.9 else Vector3.RIGHT
    var tx := normal.cross(reference).normalized()
    var ty := normal.cross(tx)
    var angles: Array[float] = []
    for idx in indices:
        var delta: Vector3 = points[idx] - center
        angles.append(atan2(delta.dot(ty), delta.dot(tx)))
    for i in range(4):
        for j in range(i + 1, 4):
            if angles[j] < angles[i]:
                var old_i := indices[i]
                var old_a := angles[i]
                indices[i] = indices[j]
                angles[i] = angles[j]
                indices[j] = old_i
                angles[j] = old_a
    return PackedInt32Array(indices)

static func face_center(sides: int, face: int) -> Vector3:
    var points := vertices(sides)
    var ids := face_indices(sides, face)
    var result := Vector3.ZERO
    for index in ids:
        result += points[index]
    return result / float(ids.size()) if ids.size() == 4 else Vector3.ZERO

static func numbers(sides: int) -> PackedInt32Array:
    var result := PackedInt32Array()
    if _n(sides) == 0:
        return result
    if sides == 10:
        # Canonical D10 visible labels 0..9; the physical 0 represents 10
        # when used as an ordinary ten-sided die. Antipodal printed digits
        # add to 9, preserving familiar tabletop orientation.
        return PackedInt32Array([10, 2, 4, 6, 8, 3, 1, 9, 7, 5])
    for value in range(1, sides + 1):
        result.append(value)
    return result

static func top_face(sides: int, pose: Basis) -> int:
    if _n(sides) == 0:
        return -1
    var best := -2.0
    var runner_up := -2.0
    var chosen := -1
    for i in range(sides):
        var score := (pose * face_normal(sides, i)).dot(Vector3.UP)
        if score > best:
            runner_up = best
            best = score
            chosen = i
        elif score > runner_up:
            runner_up = score
    # D100 adjacent normals differ by only ~7 degrees, so a D10-sized
    # 0.02 ambiguity margin would reject every legitimate D100 face.
    var tolerance := 0.0005 if sides == 100 else 0.015
    return -1 if best - runner_up <= tolerance else chosen

static func top_value(sides: int, pose: Basis) -> int:
    var face := top_face(sides, pose)
    return -1 if face < 0 else numbers(sides)[face]
