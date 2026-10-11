extends ConfirmationDialog
## M4 modal composer, opened ONLY from the hidden advanced drawer.
## Apply changes the expression, NEVER invents a dice result or saves a roll.
const Builder = preload("res://src/core/roll_pool_builder.gd")
const Formula = preload("res://src/core/roll_formula.gd")
signal formula_applied(expression: String)
var builder: RefCounted = Builder.new()
var group_list: ItemList
var die_select: OptionButton
var modifier_caption: Label
var preview: Label
var notice: Label
var selected_group: int = 0

func _make_button(parent: HBoxContainer, node_name: String, caption: String,
        action: Callable) -> Button:
    var button := Button.new()
    button.name = node_name
    button.text = caption
    button.custom_minimum_size.y = 44
    button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    button.pressed.connect(action)
    parent.add_child(button)
    return button

func _ready() -> void:
    name = "M4PhysicalPoolComposer"
    title = "НАБОР ФИЗИЧЕСКИХ КУБИКОВ"
    min_size = Vector2i(620,680)
    size = Vector2i(650,770)
    # Never let a pop-up extend below a 720x1280 mobile viewport. These are
    # logical Godot pixels; the approved camera and physical bodies are untouched.
    max_size = Vector2i(690,1020)
    get_ok_button().text = "ПРИМЕНИТЬ ФОРМУЛУ"
    get_cancel_button().text = "ОТМЕНА"
    confirmed.connect(_accept_formula)
    var column := VBoxContainer.new()
    column.custom_minimum_size = Vector2(580,585)
    column.add_theme_constant_override("separation",8)
    # AcceptDialog owns its footer / OK / CANCEL controls. A direct Window
    # child stretched the window past 1280px and sent APPLY/CANCEL offscreen.
    # Place custom contents inside the dialog's actual built-in VBox instead.
    get_vbox().add_child(column)
    var heading := Label.new()
    heading.text = "Редактируйте состав до броска. Грани определяет только физика."
    heading.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    column.add_child(heading)
    group_list = ItemList.new()
    group_list.name = "EditablePhysicalGroups"
    # A height-expanding ItemList consumed almost the ENTIRE 720x1280 phone
    # viewport (original captured frame in unified #38158723281). The real
    # count, sign, modifier, add/remove AND confirm buttons were BELOW it.
    # Keep a bounded, scrollable item list so all actual controls stay
    # touchable; ItemList scrolls internally for up to 12 source groups.
    group_list.custom_minimum_size.y = 190
    group_list.size_flags_vertical = Control.SIZE_FILL
    group_list.item_selected.connect(_select_group)
    column.add_child(group_list)
    var add_row := HBoxContainer.new()
    column.add_child(add_row)
    die_select = OptionButton.new()
    die_select.name = "ChooseGroupDieType"
    die_select.custom_minimum_size.y = 44
    die_select.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    for n in Formula.VALID_SIDES:
        die_select.add_item("D%d" % n,int(n))
    add_row.add_child(die_select)
    _make_button(add_row,"AddPhysicalGroup","ДОБАВИТЬ",_add_group)
    var edit_row := HBoxContainer.new()
    column.add_child(edit_row)
    _make_button(edit_row,"DecreaseGroupCount","−1",func(): _edit_count(-1))
    _make_button(edit_row,"IncreaseGroupCount","+1",func(): _edit_count(1))
    _make_button(edit_row,"FlipGroupSign","+/−",_flip_sign)
    _make_button(edit_row,"RemovePhysicalGroup","УДАЛИТЬ",_remove_group)
    var modifier_row := HBoxContainer.new()
    column.add_child(modifier_row)
    _make_button(modifier_row,"DecreasePoolModifier","−1",func(): _edit_modifier(-1))
    modifier_caption = Label.new()
    modifier_caption.name = "PhysicalPoolModifier"
    modifier_caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    modifier_caption.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    modifier_row.add_child(modifier_caption)
    _make_button(modifier_row,"IncreasePoolModifier","+1",func(): _edit_modifier(1))
    preview = Label.new()
    preview.name = "PhysicalPoolFormulaPreview"
    preview.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    preview.custom_minimum_size.y = 62
    column.add_child(preview)
    notice = Label.new()
    notice.name = "PhysicalPoolComposerMessage"
    notice.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    column.add_child(notice)

func open_formula(expression: String) -> bool:
    if not builder.call("load_formula",expression):
        return false
    selected_group = 0
    _refresh()
    popup_centered(Vector2i(650,770))
    return true

func _select_group(index: int) -> void:
    selected_group = index

func _refresh() -> void:
    group_list.clear()
    var groups: Array = builder.get("groups")
    for i in range(groups.size()):
        var g: Dictionary = groups[i]
        group_list.add_item("%s %d × D%d" % [
            "−" if int(g["sign"])<0 else "+",
            int(g["count"]),int(g["sides"])])
    selected_group = clampi(selected_group,0,maxi(0,groups.size()-1))
    if not groups.is_empty():
        group_list.select(selected_group)
    modifier_caption.text = "МОДИФИКАТОР: %+d" % int(builder.get("modifier"))
    preview.text = "Формула: "+str(builder.call("current_formula"))+(
        "\nФизических кубиков: %d" % int(builder.call("physical_dice_count")))
    notice.text = "До 12 групп и 64 кубиков. Применение не бросает кубики."

func _after_edit(result: bool) -> void:
    if result:
        _refresh()
    else:
        notice.text = str(builder.get("error_text"))

func _add_group() -> void:
    selected_group = (builder.get("groups") as Array).size()
    _after_edit(bool(builder.call("add_group",die_select.get_selected_id())))

func _edit_count(delta: int) -> void:
    _after_edit(bool(builder.call("adjust_count",selected_group,delta)))

func _flip_sign() -> void:
    _after_edit(bool(builder.call("change_sign",selected_group)))

func _remove_group() -> void:
    _after_edit(bool(builder.call("remove_group",selected_group)))

func _edit_modifier(delta: int) -> void:
    _after_edit(bool(builder.call("adjust_modifier",delta)))

func _accept_formula() -> void:
    var normalized := str(builder.call("current_formula"))
    # Validation also occurs on every edit, and again on submit in Main.
    formula_applied.emit(normalized)
