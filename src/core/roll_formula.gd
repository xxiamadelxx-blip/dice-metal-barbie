extends RefCounted
## M4 pure roll-formula arithmetic. NEVER generates or assigns an outcome.
## Jolt determines each actual physical upper face; this code only validates
## observed values, records explicit reroll traces and computes total/crit.
const Rules = preload("res://src/core/dice_rules.gd")
const VALID_SIDES := [4, 6, 8, 10, 12, 20, 100]
const MAX_GROUPS := 12
const MAX_PHYSICAL_DICE := 64
const MAX_MODIFIER := 10000

static func _error(message: String) -> Dictionary:
    return {"ok":false,"error":message}

static func parse(expression: String) -> Dictionary:
    var raw := expression.strip_edges().to_lower().replace(" ", "").replace("\t", "")
    if raw.is_empty() or raw.length() > 120:
        return _error("Формула пуста или слишком длинная")
    var pattern := RegEx.new()
    if pattern.compile("([+-]?)([0-9]*d[0-9]+|[0-9]+)") != OK:
        return _error("Внутренняя ошибка разбора")
    var offset := 0
    var dice_total := 0
    var modifier := 0
    var groups: Array[Dictionary] = []
    for found in pattern.search_all(raw):
        if found.get_start() != offset:
            return _error("Некорректная формула у позиции %d" % offset)
        var operation := found.get_string(1)
        if offset > 0 and operation.is_empty():
            return _error("Между частями формулы нет оператора")
        var sign := -1 if operation == "-" else 1
        var value := found.get_string(2)
        if value.contains("d"):
            var parts := value.split("d")
            var quantity: int = 1 if parts[0].is_empty() else int(parts[0])
            var sides: int = int(parts[1])
            if not VALID_SIDES.has(sides):
                return _error("Неподдерживаемый кубик D%d" % sides)
            if quantity < 1 or quantity > MAX_PHYSICAL_DICE:
                return _error("Недопустимое количество кубиков")
            dice_total += quantity
            if dice_total > MAX_PHYSICAL_DICE or groups.size() >= MAX_GROUPS:
                return _error("Слишком много физических кубиков")
            groups.append({"sides":sides,"count":quantity,"sign":sign})
        else:
            modifier += sign * int(value)
            if absi(modifier) > MAX_MODIFIER:
                return _error("Недопустимый модификатор")
        offset = found.get_end()
    if offset != raw.length() or groups.is_empty():
        return _error("Некорректная или неполная формула")
    return {"ok":true,"formula":raw,"groups":groups,
        "modifier":modifier,"physical_dice":dice_total}

static func evaluate(spec: Dictionary, observed: Array, mode: String = "normal",
        selected_d20_group: int = -1) -> Dictionary:
    ## Observations: one Array per group, one item per REAL Jolt body;
    ## each item is an int or an Array of actual successive reroll faces.
    ## Advantage/disadvantage must supply TWO distinct physical D20 results.
    if not bool(spec.get("ok",false)):
        return _error("Формула ещё не прошла проверку")
    if not ["normal","advantage","disadvantage"].has(mode):
        return _error("Неизвестный режим D20")
    var groups: Array = spec.get("groups",[])
    if observed.size() != groups.size():
        return _error("Количество групп броска не совпадает с формулой")
    var eligible: Array[int] = []
    for i in range(groups.size()):
        var g: Dictionary = groups[i]
        if int(g["sides"]) == 20 and int(g["count"]) == 1:
            eligible.append(i)
    if selected_d20_group >= 0 and not eligible.has(selected_d20_group):
        return _error("Выбранная группа для критического D20 недействительна")
    var d20_selected: int = selected_d20_group
    if selected_d20_group < 0 and eligible.size() == 1:
        d20_selected = eligible[0]
    if mode != "normal" and d20_selected == -1:
        return _error("Преимущество требует явно выбранного единственного D20")
    # If two separate D20 groups exist, no invisible automatic crit choice.
    # The UI must explicitly name the selected D20 group for crit/advantage.
    var detailed: Array[Dictionary] = []
    var value_total: int = int(spec.get("modifier",0))
    var natural_crit := "none"
    for i in range(groups.size()):
        var g: Dictionary = groups[i]
        var n := int(g["count"])
        var sides := int(g["sides"])
        var sign := int(g["sign"])
        if typeof(observed[i]) != TYPE_ARRAY:
            return _error("Не переданы физические результаты группы %d" % (i+1))
        var die_records: Array = observed[i]
        var is_adv := mode != "normal" and i == d20_selected
        var required := 2 if is_adv else n
        if die_records.size() != required:
            return _error("Группа %d требует %d реальных кубиков" % [i+1,required])
        var final_faces: Array[int] = []
        var traces: Array = []
        var percentile_sources: Array = []
        for item in die_records:
            var attempts: Array = []
            var source_faces: Array = []
            if typeof(item) == TYPE_DICTIONARY:
                if sides != 100:
                    return _error("Процентные исходные D10 допустимы только для D100")
                var raw_pair: Dictionary = item
                var history: Array = []
                if raw_pair.has("percentile_attempts"):
                    if typeof(raw_pair["percentile_attempts"]) != TYPE_ARRAY:
                        return _error("Трасса D100 должна содержать реальные пары D10")
                    history = raw_pair["percentile_attempts"]
                else:
                    history = [raw_pair]
                if history.is_empty() or history.size() > 12:
                    return _error("Неверное количество физических перебросов пары D100")
                var pair_attempts: Array = []
                for attempt in history:
                    if typeof(attempt) != TYPE_DICTIONARY:
                        return _error("Каждый переброс D100 требует две исходные грани D10")
                    var physical_pair: Dictionary = attempt
                    var ten: Variant = physical_pair.get("tens")
                    var one: Variant = physical_pair.get("ones")
                    if typeof(ten) != TYPE_INT or typeof(one) != TYPE_INT:
                        return _error("Грани процентных кубиков должны быть целыми")
                    if int(ten) < 1 or int(ten) > 10 or int(one) < 1 or int(one) > 10:
                        return _error("Невозможная физическая грань процентного D10")
                    var mapped: int = Rules.percentile((int(ten) % 10) * 10, int(one) % 10)
                    attempts.append(mapped)
                    pair_attempts.append([int(ten),int(one)])
                # Keep existing one-throw persisted format intact; only
                # a REAL paired reroll needs the nested chronological pairs.
                source_faces = pair_attempts[0] if pair_attempts.size() == 1 else pair_attempts
            else:
                attempts = item if typeof(item) == TYPE_ARRAY else [item]
            percentile_sources.append(source_faces)
            if attempts.is_empty() or attempts.size() > 12:
                return _error("Неверная последовательность перебросов")
            var sequence: Array[int] = []
            for result in attempts:
                if typeof(result) != TYPE_INT or int(result) < 1 or int(result) > sides:
                    return _error("Недопустимая физическая грань D%d" % sides)
                sequence.append(int(result))
            traces.append(sequence)
            final_faces.append(sequence[-1])
        var selected: Array[int] = []
        if is_adv:
            selected.append(Rules.choose_advantage(final_faces[0],final_faces[1],
                mode == "disadvantage"))
        else:
            selected = final_faces.duplicate()
        var partial := 0
        for result in selected:
            partial += result
        value_total += sign * partial
        if i == d20_selected and selected.size() == 1 and sides == 20:
            natural_crit = Rules.critical_d20(selected[0])
        detailed.append({"sides":sides,"sign":sign,"count":n,"attempts":traces,
            "percentile_source_d10_faces":percentile_sources,
            "observed_faces":final_faces,"kept_faces":selected,
            "subtotal":sign*partial,"selected_d20":i==d20_selected})
    return {"ok":true,"schema_version":1,"formula":spec["formula"],
        "groups":detailed,"modifier":int(spec["modifier"]),
        "total":value_total,"d20_mode":mode,"natural_d20_critical":natural_crit,
        "source":"actual_physical_faces_required"}
