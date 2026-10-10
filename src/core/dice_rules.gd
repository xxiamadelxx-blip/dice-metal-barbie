extends RefCounted
## Pure mechanics, independent of visuals and physics.

static func critical_d20(face: int) -> String:
    if face == 20:
        return "success"
    if face == 1:
        return "failure"
    return "none"

static func percentile(tens: int, ones: int) -> int:
    ## Tens die: 0,10,...90; ones die: 0..9; 00+0 = 100.
    if tens < 0 or tens > 90 or tens % 10 != 0 or ones < 0 or ones > 9:
        return -1
    if tens == 0 and ones == 0:
        return 100
    return tens + ones

static func choose_advantage(first: int, second: int, disadvantage: bool = false) -> int:
    if first < 1 or first > 20 or second < 1 or second > 20:
        return -1
    return mini(first, second) if disadvantage else maxi(first, second)

static func sum_rolls(faces: Array[int], modifier: int = 0) -> int:
    var total := modifier
    for face in faces:
        total += face
    return total

