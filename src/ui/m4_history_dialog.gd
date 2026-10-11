extends AcceptDialog
## M4 complete local read-only history browser. No server, no invented rolls.
## Source entries are the previously persisted and revalidated real Jolt faces.
var stored_history: Array = []
var displayed_indices: Array[int] = []
var search_field: LineEdit
var rows: ItemList
var details: RichTextLabel
var header: Label

func _ready() -> void:
    name = "M4PhysicalRollHistory"
    title = "ИСТОРИЯ ФИЗИЧЕСКИХ БРОСКОВ"
    min_size = Vector2i(600,720)
    size = Vector2i(635,850)
    get_ok_button().text = "ЗАКРЫТЬ"
    # AcceptDialog in Godot 4.6.3 does not expose get_vbox(); custom
    # content is an actual Control child, not an undocumented API call.
    var root_col := VBoxContainer.new()
    root_col.name = "CompleteHistoryContent"
    root_col.custom_minimum_size = Vector2(565,610)
    root_col.size_flags_vertical = Control.SIZE_EXPAND_FILL
    root_col.add_theme_constant_override("separation",10)
    add_child(root_col)
    header = Label.new()
    header.name = "HistoryRollCount"
    header.text = "История ещё пуста"
    root_col.add_child(header)
    search_field = LineEdit.new()
    search_field.name = "SearchPhysicalRollHistory"
    search_field.placeholder_text = "Найти по формуле, числу, кубику или криту"
    search_field.custom_minimum_size.y = 44
    search_field.text_changed.connect(_filter_history)
    root_col.add_child(search_field)
    rows = ItemList.new()
    rows.name = "AllSavedRolls"
    rows.size_flags_vertical = Control.SIZE_EXPAND_FILL
    rows.custom_minimum_size.y = 270
    rows.item_selected.connect(_choose_visible_row)
    root_col.add_child(rows)
    var detail_caption := Label.new()
    detail_caption.text = "ДЕТАЛИ ФИЗИЧЕСКОГО РЕЗУЛЬТАТА"
    root_col.add_child(detail_caption)
    details = RichTextLabel.new()
    details.name = "ActualIndividualFacesAndRerolls"
    details.bbcode_enabled = false
    details.scroll_active = true
    details.selection_enabled = true
    details.custom_minimum_size.y = 270
    details.size_flags_vertical = Control.SIZE_EXPAND_FILL
    root_col.add_child(details)
    _filter_history("")

func set_history(history: Array) -> void:
    # Defensive deep copy: viewing, filtering or closing is read-only.
    stored_history = history.duplicate(true)
    if is_node_ready():
        _filter_history(search_field.text)

func _display_line(entry: Dictionary, index: int) -> String:
    var expression := str(entry.get("formula","?"))
    var result := str(entry.get("total","?"))
    var count := (entry.get("groups",[]) as Array).size()
    var stamp := int(entry.get("timestamp_unix",0))
    var time_text := Time.get_datetime_string_from_unix_time(stamp,true) if stamp>0 else "Без времени"
    return "%03d · %s = %s  ·  %d гр.  ·  %s" % [
        index+1,expression,result,count,time_text]

func _filter_history(query: String) -> void:
    if rows == null:
        return
    rows.clear()
    displayed_indices.clear()
    var q := query.strip_edges().to_lower()
    for i in range(stored_history.size()):
        var raw: Variant = stored_history[i]
        if typeof(raw) != TYPE_DICTIONARY:
            continue
        var row: Dictionary = raw
        var needle := ("%s %s %s" % [
            str(row.get("formula","")),str(row.get("total","")),
            str(row.get("natural_d20_critical",""))]).to_lower()
        if q.is_empty() or needle.contains(q):
            displayed_indices.append(i)
            rows.add_item(_display_line(row,i))
    header.text = "Всего записей: %d · найдено: %d" % [
        stored_history.size(),displayed_indices.size()]
    if not displayed_indices.is_empty():
        rows.select(0)
        _choose_visible_row(0)
    elif details != null:
        details.text = "Нет сохранённых бросков с таким условием."

func _choose_visible_row(displayed_index: int) -> void:
    if details == null or displayed_index < 0 or displayed_index >= displayed_indices.size():
        return
    var index := displayed_indices[displayed_index]
    var entry: Dictionary = stored_history[index]
    var lines: Array[String] = []
    lines.append("Формула: %s" % str(entry.get("formula","?")))
    lines.append("ИТОГ: %s" % str(entry.get("total","?")))
    lines.append("Модификатор: %+d" % int(entry.get("modifier",0)))
    var mode := str(entry.get("d20_mode","normal"))
    lines.append("Режим D20: %s" % mode)
    var critical := str(entry.get("natural_d20_critical","none"))
    if critical == "success":
        lines.append("Натуральная 20: критический успех")
    elif critical == "failure":
        lines.append("Натуральная 1: критическая неудача")
    var groups: Array = entry.get("groups",[])
    for gi in range(groups.size()):
        if typeof(groups[gi]) != TYPE_DICTIONARY:
            continue
        var group: Dictionary = groups[gi]
        var sides := int(group.get("sides",0))
        var sign := int(group.get("sign",1))
        lines.append("Группа %d: %sD%d · сумма %+d" % [
            gi+1,"+" if sign>=0 else "-",sides,int(group.get("subtotal",0))])
        var attempts: Array = group.get("attempts",[])
        var chosen: Array = group.get("kept_faces",[])
        var percentile: Array = group.get("percentile_source_d10_faces",[])
        var raw_histories: Array = group.get("percentile_source_d10_attempts",[])
        var reroll_modes: Array = group.get("percentile_reroll_modes",[])
        # Advantage/disadvantage keeps only ONE of the two real D20 bodies.
        # The kept face belongs to the ACTUAL winning source die, not the
        # first entry of the array by accident. On a tie, keep the first.
        var is_advantage := sides == 20 and mode != "normal" and (
            attempts.size() == 2 and chosen.size() == 1)
        var kept_source_marked := false
        for di in range(attempts.size()):
            var source: Variant = attempts[di]
            var source_faces: Array = source if typeof(source) == TYPE_ARRAY else [source]
            var ordered: Array[String] = []
            for physical_face in source_faces:
                ordered.append(str(int(physical_face)))
            var original_text := " → ".join(ordered)
            var selected_text := "(не выбран)"
            if is_advantage:
                if not kept_source_marked and not source_faces.is_empty() and (
                        int(source_faces[-1]) == int(chosen[0])):
                    selected_text = str(int(chosen[0]))
                    kept_source_marked = true
            elif di < chosen.size():
                selected_text = str(int(chosen[di]))
            var content := "  Кубик %d: %s  ·  засчитано: %s" % [
                di+1,original_text,selected_text]
            if source_faces.size()>1:
                content += "  ·  физический переброс"
            if di < percentile.size() and typeof(percentile[di]) == TYPE_ARRAY:
                var digits: Array = percentile[di]
                if digits.size()==2:
                    content += "  ·  итоговая физическая пара D10: %d/%d" % [
                        int(digits[0]),int(digits[1])]
                if di<raw_histories.size() and typeof(raw_histories[di])==TYPE_ARRAY:
                    var pairs: Array = raw_histories[di]
                    if pairs.size()>1:
                        var sequence: Array[String] = []
                        for recorded in pairs:
                            if typeof(recorded)==TYPE_ARRAY and recorded.size()==2:
                                sequence.append("%d/%d" % [int(recorded[0]),int(recorded[1])])
                        content += "  ·  реальные пары D10: " + " → ".join(sequence)
                        if di<reroll_modes.size() and typeof(reroll_modes[di])==TYPE_ARRAY:
                            var modes: Array = reroll_modes[di]
                            if not modes.is_empty():
                                content += "  ·  действия: " + ", ".join(modes)
            lines.append(content)
    lines.append("")
    lines.append("Источник: сохранённые фактические верхние грани Godot/Jolt")
    details.text = "\n".join(lines)

func visible_record_count() -> int:
    return displayed_indices.size()

func selected_record_index() -> int:
    if rows == null:
        return -1
    var selected: PackedInt32Array = rows.get_selected_items()
    if selected.is_empty():
        return -1
    var i: int = selected[0]
    return displayed_indices[i] if i >= 0 and i < displayed_indices.size() else -1
