extends PanelContainer
## M4 minimal WORKING advanced drawer. Approved Concept 3 remains authority;
## this is functional UX only, not final M5 typography/art.
signal physical_roll_requested(expression: String, mode: String, d100_mode: String)
signal preset_save_requested(title: String, expression: String, mode: String, d100_mode: String)
signal preset_delete_requested(title: String)
signal history_clear_requested
signal history_open_requested
signal physical_reroll_requested(group_index: int, die_index: int, digit: String)

var formula_input: LineEdit
var pool_edit_button: Button
var pool_editor: ConfirmationDialog
var name_input: LineEdit
var modes: OptionButton
var hundred_modes: OptionButton
var preset_select: OptionButton
var roll_button: Button
var reroll_picker: OptionButton
var reroll_button: Button
var reroll_slots: Array[Dictionary] = []
var feedback: Label
var history_preview: Label
var saved_titles: Array[String] = []

func _ready() -> void:
    name = "M4AdvancedRollDrawer"
    visible = false
    set_anchors_preset(Control.PRESET_TOP_WIDE)
    offset_left = 16
    offset_right = -16
    offset_top = 105
    offset_bottom = 580
    var style := StyleBoxFlat.new()
    style.bg_color = Color(0.028,0.033,0.045,0.98)
    style.border_color = Color(0.41,0.32,0.21)
    style.set_border_width_all(1)
    style.set_corner_radius_all(14)
    style.set_content_margin_all(16)
    add_theme_stylebox_override("panel",style)
    var content := VBoxContainer.new()
    content.add_theme_constant_override("separation",8)
    add_child(content)

    var caption := Label.new()
    caption.text = "СОСТАВНОЙ БРОСОК"
    caption.add_theme_font_size_override("font_size",17)
    content.add_child(caption)
    # Keep existing Android coordinates of the real formula/throw/reroll
    # controls. The extra builder sits INSIDE the existing 46px formula row.
    var formula_row := HBoxContainer.new()
    formula_row.add_theme_constant_override("separation",6)
    content.add_child(formula_row)
    formula_input = LineEdit.new()
    formula_input.name = "PhysicalFormulaInput"
    formula_input.placeholder_text = "Например: 2d6+1d20-3"
    formula_input.text = "2d6+1d20-3"
    formula_input.custom_minimum_size.y = 46
    formula_input.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    formula_row.add_child(formula_input)
    pool_edit_button = Button.new()
    pool_edit_button.name = "EditPhysicalPool"
    pool_edit_button.text = "НАБОР"
    pool_edit_button.tooltip_text = "Добавить, убрать, изменить количество кубиков и модификатор"
    pool_edit_button.custom_minimum_size = Vector2(84,46)
    pool_edit_button.pressed.connect(_open_pool_editor)
    formula_row.add_child(pool_edit_button)
    var modes_row := HBoxContainer.new()
    modes_row.add_theme_constant_override("separation",8)
    content.add_child(modes_row)
    modes = OptionButton.new()
    modes.name = "D20AdvantageMode"
    modes.add_item("Обычный",0)
    modes.add_item("Преимущество D20",1)
    modes.add_item("Помеха D20",2)
    modes.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    modes.custom_minimum_size.y = 44
    modes_row.add_child(modes)
    hundred_modes = OptionButton.new()
    hundred_modes.name = "D100PhysicalMode"
    hundred_modes.add_item("2×D10",0)
    hundred_modes.add_item("1×D100",1)
    hundred_modes.custom_minimum_size.y = 44
    modes_row.add_child(hundred_modes)
    roll_button = Button.new()
    roll_button.name = "ThrowPhysicalFormula"
    roll_button.text = "БРОСИТЬ ФОРМУЛУ"
    roll_button.custom_minimum_size.y = 50
    roll_button.pressed.connect(_request_throw)
    content.add_child(roll_button)

    # Select ONE true source body. Paired D100 exposes separate tens/ones D10,
    # each with a full offline chronology of both original physical faces.
    var reroll_row := HBoxContainer.new()
    reroll_row.add_theme_constant_override("separation",8)
    content.add_child(reroll_row)
    reroll_picker = OptionButton.new()
    reroll_picker.name = "ChoosePhysicalDieToReroll"
    reroll_picker.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    reroll_picker.custom_minimum_size.y = 44
    reroll_picker.add_item("Сначала бросьте формулу")
    reroll_picker.disabled = true
    # Native player touch proves the chosen *source rigid body*, not a synthetic
    # ADB tap. This debug-only marker is independently required by Android QA.
    reroll_picker.item_selected.connect(_source_picker_changed_by_user)
    reroll_row.add_child(reroll_picker)
    reroll_button = Button.new()
    reroll_button.name = "RerollChosenPhysicalDie"
    reroll_button.text = "ПЕРЕБРОСИТЬ"
    reroll_button.custom_minimum_size.y = 44
    reroll_button.disabled = true
    reroll_button.pressed.connect(_request_physical_reroll)
    reroll_row.add_child(reroll_button)

    var preset_row := HBoxContainer.new()
    preset_row.add_theme_constant_override("separation",8)
    content.add_child(preset_row)
    name_input = LineEdit.new()
    name_input.name = "PresetName"
    name_input.placeholder_text = "Название пресета"
    name_input.custom_minimum_size.y = 42
    name_input.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    preset_row.add_child(name_input)
    var save := Button.new()
    save.name = "SaveNamedPreset"
    save.text = "СОХРАНИТЬ"
    save.pressed.connect(_request_save)
    preset_row.add_child(save)
    var load_row := HBoxContainer.new()
    load_row.add_theme_constant_override("separation",8)
    content.add_child(load_row)
    preset_select = OptionButton.new()
    preset_select.name = "StoredPresets"
    preset_select.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    load_row.add_child(preset_select)
    var use := Button.new()
    use.name = "ApplySavedPreset"
    use.text = "ВЫБРАТЬ"
    use.pressed.connect(_apply_preset)
    load_row.add_child(use)
    var delete := Button.new()
    delete.name = "RemoveSavedPreset"
    delete.text = "УДАЛИТЬ"
    delete.pressed.connect(_request_delete)
    load_row.add_child(delete)

    var history_row := HBoxContainer.new()
    content.add_child(history_row)
    history_preview = Label.new()
    history_preview.name = "SavedHistoryPreview"
    history_preview.text = "История бросков пуста"
    history_preview.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    history_preview.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    history_row.add_child(history_preview)
    var view_all := Button.new()
    view_all.name = "OpenFullPhysicalHistory"
    view_all.text = "ИСТОРИЯ"
    view_all.custom_minimum_size.y = 44
    view_all.pressed.connect(func(): history_open_requested.emit())
    history_row.add_child(view_all)
    var clear := Button.new()
    clear.name = "ClearSavedHistory"
    clear.text = "ОЧИСТИТЬ"
    clear.pressed.connect(func(): history_clear_requested.emit())
    history_row.add_child(clear)
    feedback = Label.new()
    feedback.name = "M4AdvancedMessage"
    feedback.text = "Числа берутся только с остановившихся физических граней."
    feedback.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    content.add_child(feedback)

func _open_pool_editor() -> void:
    if pool_edit_button.disabled:
        return
    if pool_editor == null:
        pool_editor = preload("res://src/ui/m4_pool_editor_dialog.gd").new()
        add_child(pool_editor)
        pool_editor.confirmed.connect(_apply_edited_pool)
    if not bool(pool_editor.call("load_expression",formula_input.text)):
        feedback.text = "Проверьте формулу перед редактированием набора."
        return
    pool_editor.popup_centered_ratio(0.82)

func _apply_edited_pool() -> void:
    if pool_editor == null or pool_edit_button.disabled:
        return
    var composed: String = str(pool_editor.call("composed_expression"))
    var parsed: Dictionary = preload("res://src/core/roll_formula.gd").parse(composed)
    if not bool(parsed.get("ok",false)):
        feedback.text = str(parsed.get("error","Не удалось изменить набор"))
        return
    formula_input.text = composed
    feedback.text = "Набор обновлён: " + composed
    if OS.is_debug_build():
        print("DICE_M4_POOL_APPLIED formula=" + composed)

func _selected_mode() -> String:
    match modes.selected:
        1: return "advantage"
        2: return "disadvantage"
    return "normal"

func _hundred_mode() -> String:
    return "single" if hundred_modes.selected == 1 else "pair"

func _request_throw() -> void:
    physical_roll_requested.emit(formula_input.text,_selected_mode(),_hundred_mode())

func _source_picker_changed_by_user(index: int) -> void:
    if index < 0 or index >= reroll_slots.size():
        return
    if OS.is_debug_build():
        var chosen: Dictionary = reroll_slots[index]
        print("DICE_M4_SOURCE_SELECTED group=%d die=%d digit=%s" % [
            int(chosen["group"]),int(chosen["die"]),str(chosen.get("digit",""))])

func _request_physical_reroll() -> void:
    var idx := reroll_picker.selected
    if idx < 0 or idx >= reroll_slots.size():
        feedback.text = "Сначала выберите физический кубик."
        return
    var chosen: Dictionary = reroll_slots[idx]
    physical_reroll_requested.emit(int(chosen["group"]),int(chosen["die"]),
        str(chosen.get("digit","")))

func set_real_roll_result(outcome: Dictionary) -> void:
    reroll_slots.clear()
    reroll_picker.clear()
    if bool(outcome.get("ok",false)):
        var all_groups: Array = outcome.get("groups",[])
        for gi in range(all_groups.size()):
            var group: Dictionary = all_groups[gi]
            var attempts: Array = group.get("attempts",[])
            var faces: Array = group.get("observed_faces",[])
            var percentiles: Array = group.get("percentile_source_d10_faces",[])
            for di in range(attempts.size()):
                var is_pair := false
                if di < percentiles.size() and typeof(percentiles[di])==TYPE_ARRAY:
                    is_pair = (percentiles[di] as Array).size()==2
                if is_pair:
                    var pair: Array = percentiles[di]
                    for digit_name in ["tens","ones"]:
                        var nth: int = 0 if digit_name=="tens" else 1
                        reroll_slots.append({"group":gi,"die":di,"digit":digit_name})
                        reroll_picker.add_item("D100 №%d · %s D10 · грань %d" %
                            [di+1,"десятки" if nth==0 else "единицы",int(pair[nth])])
                else:
                    var face: int = int(faces[di]) if di < faces.size() else -1
                    reroll_slots.append({"group":gi,"die":di,"digit":""})
                    reroll_picker.add_item("D%d · №%d · выпало %d" %
                        [int(group["sides"]),di+1,face])
    if reroll_slots.is_empty():
        reroll_picker.add_item("Нет доступных кубиков для переброса")
    reroll_picker.disabled = reroll_slots.is_empty()
    reroll_button.disabled = reroll_slots.is_empty()

func _request_save() -> void:
    preset_save_requested.emit(name_input.text,formula_input.text,
        _selected_mode(),_hundred_mode())

func _selected_title() -> String:
    var idx := preset_select.selected
    return saved_titles[idx] if idx >= 0 and idx < saved_titles.size() else ""

func _request_delete() -> void:
    var title := _selected_title()
    if not title.is_empty():
        preset_delete_requested.emit(title)

func _apply_preset() -> void:
    var title := _selected_title()
    if title.is_empty():
        feedback.text = "Сначала сохраните пресет."
        return
    var state: Dictionary = get_meta("persisted_presets",{})
    var preset: Dictionary = state.get(title,{})
    formula_input.text = str(preset.get("formula",""))
    modes.select(["normal","advantage","disadvantage"].find(
        str(preset.get("d20_mode","normal"))))
    hundred_modes.select(1 if str(preset.get("d100_mode","pair")) == "single" else 0)
    name_input.text = title
    feedback.text = "Пресет применён: "+title

func show_message(message: String) -> void:
    feedback.text = message

func set_roll_locked(locked: bool) -> void:
    roll_button.disabled = locked
    formula_input.editable = not locked
    pool_edit_button.disabled = locked
    if locked and is_instance_valid(pool_editor) and pool_editor.visible:
        pool_editor.hide()
    if locked:
        reroll_button.disabled = true
        reroll_picker.disabled = true
    else:
        reroll_button.disabled = reroll_slots.is_empty()
        reroll_picker.disabled = reroll_slots.is_empty()

func refresh_local_state(data: Dictionary) -> void:
    var presets: Dictionary = data.get("presets",{})
    set_meta("persisted_presets",presets.duplicate(true))
    saved_titles.clear()
    for title in presets:
        saved_titles.append(str(title))
    saved_titles.sort()
    preset_select.clear()
    for title in saved_titles:
        preset_select.add_item(title)
    var history: Array = data.get("history",[])
    if history.is_empty():
        history_preview.text = "История бросков пуста"
    else:
        var summaries: Array[String] = []
        for i in range(mini(2,history.size())):
            var entry: Dictionary = history[i]
            summaries.append("%s = %d" % [str(entry.get("formula","?")),
                int(entry.get("total",0))])
        history_preview.text = "  ·  ".join(summaries)
