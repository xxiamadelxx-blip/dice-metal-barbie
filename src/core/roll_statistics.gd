extends RefCounted
## Read-only saved RESULT receipts, not RNG, not independent physical trials.
static func summarize(history: Array) -> Dictionary:
    var count := 0
    var total_sum := 0
    var low := 0
    var high := 0
    var crit20 := 0
    var crit1 := 0
    var rerolls := 0
    for raw in history:
        if typeof(raw) != TYPE_DICTIONARY:
            continue
        var receipt: Dictionary = raw
        if not bool(receipt.get("ok",false)) or str(receipt.get("source","")) != "actual_physical_faces_required":
            continue
        var number: Variant = receipt.get("total")
        if not [TYPE_INT,TYPE_FLOAT].has(typeof(number)):
            continue
        var value := int(number)
        if float(value) != float(number) or absi(value) > 20000:
            continue
        var groups: Variant = receipt.get("groups")
        if typeof(groups) != TYPE_ARRAY or (groups as Array).is_empty():
            continue
        if count == 0:
            low = value
            high = value
        else:
            low = mini(low,value)
            high = maxi(high,value)
        count += 1
        total_sum += value
        match str(receipt.get("natural_d20_critical","none")):
            "success": crit20 += 1
            "failure": crit1 += 1
        var has_reroll := false
        for source in groups:
            if typeof(source) != TYPE_DICTIONARY:
                continue
            var g: Dictionary = source
            if typeof(g.get("attempts")) != TYPE_ARRAY:
                continue
            for trace in (g["attempts"] as Array):
                if typeof(trace) == TYPE_ARRAY and (trace as Array).size() > 1:
                    has_reroll = true
        if has_reroll:
            rerolls += 1
    return {"records":count,"total_sum":total_sum,
        "average":float(total_sum)/float(count) if count>0 else 0.0,
        "minimum":low,"maximum":high,"crit20":crit20,"crit1":crit1,
        "reroll_receipts":rerolls}

static func describe(s: Dictionary) -> String:
    if int(s["records"]) == 0:
        return "Статистика: нет сохранённых результатов в выборке."
    return ("Записей: %d · среднее: %.1f · мин/макс: %d/%d\n" +
        "Крит. 20: %d · крит. 1: %d · после переброса: %d\n" +
        "Статистика записей, не проверка равномерности физических кубиков.") % [
        int(s["records"]),float(s["average"]),int(s["minimum"]),int(s["maximum"]),
        int(s["crit20"]),int(s["crit1"]),int(s["reroll_receipts"])]
