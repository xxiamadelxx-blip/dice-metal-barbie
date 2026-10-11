extends RefCounted
## M4 UI-only expression builder. This never calculates, predicts or changes
## a die face: Formula.parse is the single rules/limits authority, Jolt rolls.
const Formula = preload("res://src/core/roll_formula.gd")
var groups: Array[Dictionary] = []
var modifier: int = 0
var error_text: String = ""

func load_formula(expression: String) -> bool:
    var parsed: Dictionary = Formula.parse(expression)
    if not bool(parsed.get("ok",false)):
        error_text = str(parsed.get("error","Неправильная формула"))
        return false
    var fresh: Array[Dictionary] = []
    for g in (parsed["groups"] as Array):
        fresh.append((g as Dictionary).duplicate(true))
    groups = fresh
    modifier = int(parsed["modifier"])
    error_text = ""
    return true

func _render(candidate: Array[Dictionary], mod: int) -> String:
    var result := ""
    for g in candidate:
        var sign := int(g["sign"])
        if not result.is_empty():
            result += "-" if sign < 0 else "+"
        elif sign < 0:
            result += "-"
        result += "%dd%d" % [int(g["count"]),int(g["sides"])]
    if mod != 0:
        result += ("%+d" % mod)
    return result

func current_formula() -> String:
    return _render(groups,modifier)

func _commit(candidate: Array[Dictionary], candidate_modifier: int) -> bool:
    var spec: Dictionary = Formula.parse(_render(candidate,candidate_modifier))
    if not bool(spec.get("ok",false)):
        error_text = str(spec.get("error","Формула не поддерживается"))
        return false
    groups = candidate.duplicate(true)
    modifier = candidate_modifier
    error_text = ""
    return true

func add_group(sides: int, sign: int = 1) -> bool:
    if not Formula.VALID_SIDES.has(sides) or not [-1,1].has(sign):
        error_text = "Неподдерживаемый кубик или знак"
        return false
    var candidate: Array[Dictionary] = groups.duplicate(true)
    candidate.append({"sides":sides,"count":1,"sign":sign})
    return _commit(candidate,modifier)

func adjust_count(group_index: int, delta: int) -> bool:
    if group_index < 0 or group_index >= groups.size() or absi(delta)!=1:
        error_text = "Сначала выберите группу"
        return false
    var candidate: Array[Dictionary] = groups.duplicate(true)
    candidate[group_index]["count"] = int(candidate[group_index]["count"])+delta
    return _commit(candidate,modifier)

func change_sign(group_index: int) -> bool:
    if group_index < 0 or group_index >= groups.size():
        error_text = "Сначала выберите группу"
        return false
    var candidate: Array[Dictionary] = groups.duplicate(true)
    candidate[group_index]["sign"] = -int(candidate[group_index]["sign"])
    return _commit(candidate,modifier)

func remove_group(group_index: int) -> bool:
    if group_index < 0 or group_index >= groups.size() or groups.size() <= 1:
        error_text = "В наборе должен остаться хотя бы один кубик"
        return false
    var candidate: Array[Dictionary] = groups.duplicate(true)
    candidate.remove_at(group_index)
    return _commit(candidate,modifier)

func adjust_modifier(delta: int) -> bool:
    if absi(delta)!=1:
        error_text = "Модификатор меняется по одному"
        return false
    return _commit(groups.duplicate(true),modifier+delta)

func physical_dice_count() -> int:
    var total := 0
    for g in groups:
        total += int(g["count"])
    return total
