extends ConfirmationDialog
## M4 genuine player-facing, DISMISSIBLE editor of a formula-backed die pool.
## Edits are draft-only; pressing Apply changes the LineEdit, NOT physics,
## saved history or the actual result. Pure RollFormula.parse is the arbiter.
const Formula = preload("res://src/core/roll_formula.gd")
const SIDES := [4,6,8,10,12,20,100]
var draft_groups: Array[Dictionary] = []
var draft_modifier := 0
var selected_group := 0
var available_die: OptionButton
var add_sign: OptionButton
var group_list: ItemList
var preview: Label
var status: Label
var modifier_label: Label

func _ready() -> void:
    name = "M4EditablePhysicalPool"
    title = "НАБОР ФИЗИЧЕСКИХ КУБИКОВ"
    min_size = Vector2i(555,680)
    size = Vector2i(620,720)
    get_ok_button().text = "ПРИМЕНИТЬ"
    get_cancel_button().text = "ОТМЕНА"
    var content := VBoxContainer.new()
    content.name = "PoolEditingContent"
    content.custom_minimum_size = Vector2(515,535)
    content.add_theme_constant_override("separation",8)
    add_child(content)
    var explanation := Label.new()
    explanation.text = "Соберите формулу. Бросок начнётся только после подтверждения."
    explanation.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    content.add_child(explanation)
    var add_row := HBoxContainer.new()
    add_row.add_theme_constant_override("separation",8)
    content.add_child(add_row)
    available_die = OptionButton.new()
    available_die.name = "ChooseDieForPool"
    available_die.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    available_die.custom_minimum_size.y = 44
    for sides in SIDES:
        available_die.add_item("D%d" % sides,sides)
    add_row.add_child(available_die)
    add_sign = OptionButton.new()
    add_sign.name = "NewGroupSign"
    add_sign.add_item("+",0)
    add_sign.add_item("−",1)
    add_sign.custom_minimum_size = Vector2(64,44)
    add_row.add_child(add_sign)
    var add := Button.new()
    add.name = "AddDieToPool"
    add.text = "ДОБАВИТЬ"
    add.custom_minimum_size.y = 44
    add.pressed.connect(_add_group)
    add_row.add_child(add)
    group_list = ItemList.new()
    group_list.name = "EditableDiceGroups"
    group_list.custom_minimum_size.y = 210
    group_list.size_flags_vertical = Control.SIZE_EXPAND_FILL
    group_list.item_selected.connect(_select_group)
    content.add_child(group_list)
    var edit_row := HBoxContainer.new()
    edit_row.add_theme_constant_override("separation",6)
    content.add_child(edit_row)
    var less := Button.new()
    less.name = "PoolOneDieLess"
    less.text = "−1"
    less.custom_minimum_size.y = 44
    less.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    less.pressed.connect(func(): _change_count(-1))
    edit_row.add_child(less)
    var more := Button.new()
    more.name = "PoolOneDieMore"
    more.text = "+1"
    more.custom_minimum_size.y = 44
    more.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    more.pressed.connect(func(): _change_count(1))
    edit_row.add_child(more)
    var change_sign := Button.new()
    change_sign.name = "ReversePoolGroupSign"
    change_sign.text = "+/−"
    change_sign.custom_minimum_size.y = 44
    change_sign.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    change_sign.pressed.connect(_toggle_group_sign)
    edit_row.add_child(change_sign)
    var remove := Button.new()
    remove.name = "RemoveDieFromPool"
    remove.text = "УБРАТЬ"
    remove.custom_minimum_size.y = 44
    remove.pressed.connect(_remove_group)
    edit_row.add_child(remove)
    var mod_row := HBoxContainer.new()
    mod_row.add_theme_constant_override("separation",8)
    content.add_child(mod_row)
    var label := Label.new()
    label.text = "Модификатор"
    label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    mod_row.add_child(label)
    var mod_less := Button.new()
    mod_less.name = "PoolModifierMinus"
    mod_less.text = "−"
    mod_less.custom_minimum_size = Vector2(48,44)
    mod_less.pressed.connect(func(): _change_modifier(-1))
    mod_row.add_child(mod_less)
    modifier_label = Label.new()
    modifier_label.name = "PoolModifierValue"
    modifier_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    modifier_label.custom_minimum_size.x = 75
    mod_row.add_child(modifier_label)
    var mod_more := Button.new()
    mod_more.name = "PoolModifierPlus"
    mod_more.text = "+"
    mod_more.custom_minimum_size = Vector2(48,44)
    mod_more.pressed.connect(func(): _change_modifier(1))
    mod_row.add_child(mod_more)
    preview = Label.new()
    preview.name = "EditedPhysicalFormula"
    preview.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    content.add_child(preview)
    status = Label.new()
    status.name = "PoolValidationMessage"
    status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    content.add_child(status)
    _refresh()

func load_expression(expression: String) -> bool:
    var parsed: Dictionary = Formula.parse(expression)
    if not bool(parsed.get("ok",false)):
        if status != null:
            status.text = str(parsed.get("error","Недопустимая формула"))
        return false
    draft_groups.clear()
    for group in (parsed["groups"] as Array):
        draft_groups.append((group as Dictionary).duplicate(true))
    draft_modifier = int(parsed["modifier"])
    selected_group = 0
    _refresh()
    return true

func _compose(groups: Array, modifier: int) -> String:
    var result := ""
    for i in range(groups.size()):
        var group: Dictionary = groups[i]
        var sign := "-" if int(group["sign"]) < 0 else ("+" if i > 0 else "")
        result += sign + str(int(group["count"])) + "d" + str(int(group["sides"]))
    if modifier > 0:
        result += "+" + str(modifier)
    elif modifier < 0:
        result += str(modifier)
    return result

func composed_expression() -> String:
    return _compose(draft_groups,draft_modifier)

func _refresh() -> void:
    if group_list == null:
        return
    group_list.clear()
    for i in range(draft_groups.size()):
        var g: Dictionary = draft_groups[i]
        group_list.add_item("%02d · %s%d × D%d" % [
            i+1,"+" if int(g["sign"]) > 0 else "−",
            int(g["count"]),int(g["sides"])])
    if not draft_groups.is_empty():
        selected_group = clampi(selected_group,0,draft_groups.size()-1)
        group_list.select(selected_group)
    var formula := composed_expression()
    var parsed: Dictionary = Formula.parse(formula)
    preview.text = "Формула броска: " + formula
    modifier_label.text = "%+d" % draft_modifier
    status.text = ("Кубиков: %d · групп: %d" % [
        int(parsed.get("physical_dice",0)),draft_groups.size()]) if bool(parsed.get("ok",false)) else str(parsed.get("error","Ошибка формулы"))
    get_ok_button().disabled = not bool(parsed.get("ok",false))

func _select_group(index: int) -> void:
    if index >= 0 and index < draft_groups.size():
        selected_group = index

func _try_update(groups: Array, modifier: int, index: int) -> void:
    var expression := _compose(groups,modifier)
    var parsed: Dictionary = Formula.parse(expression)
    if not bool(parsed.get("ok",false)):
        status.text = str(parsed.get("error","Ограничение набора"))
        return
    draft_groups.clear()
    for group in groups:
        draft_groups.append((group as Dictionary).duplicate(true))
    draft_modifier = modifier
    selected_group = index
    _refresh()

func _add_group() -> void:
    if available_die.selected < 0:
        return
    var groups: Array = draft_groups.duplicate(true)
    groups.append({"sides":available_die.get_item_id(available_die.selected),
        "count":1,"sign":-1 if add_sign.selected==1 else 1})
    _try_update(groups,draft_modifier,groups.size()-1)

func _change_count(delta: int) -> void:
    if selected_group < 0 or selected_group >= draft_groups.size():
        return
    var groups: Array = draft_groups.duplicate(true)
    var g: Dictionary = groups[selected_group]
    var changed := int(g["count"])+delta
    if changed < 1:
        status.text = "Минимум один кубик в группе. Для удаления нажмите УБРАТЬ."
        return
    g["count"] = changed
    _try_update(groups,draft_modifier,selected_group)

func _toggle_group_sign() -> void:
    if selected_group < 0 or selected_group >= draft_groups.size():
        return
    var groups: Array = draft_groups.duplicate(true)
    var g: Dictionary = groups[selected_group]
    g["sign"] = -int(g["sign"])
    _try_update(groups,draft_modifier,selected_group)

func _remove_group() -> void:
    if selected_group < 0 or selected_group >= draft_groups.size():
        return
    if draft_groups.size()==1:
        status.text = "Нельзя удалить последний кубик."
        return
    var groups: Array = draft_groups.duplicate(true)
    groups.remove_at(selected_group)
    _try_update(groups,draft_modifier,mini(selected_group,groups.size()-1))

func _change_modifier(delta: int) -> void:
    _try_update(draft_groups.duplicate(true),draft_modifier+delta,selected_group)
