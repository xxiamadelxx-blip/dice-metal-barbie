extends RefCounted
## M4 offline, versioned history/presets. Only receives completed, validated
## physical-roll calculations; NEVER assigns a die value or contacts a server.
const Formula = preload("res://src/core/roll_formula.gd")
const SCHEMA_VERSION := 1
const MAX_HISTORY := 200
const MAX_PRESETS := 40
const DEFAULT_PATH := "user://dice_state_v1.json"
var path: String
var state: Dictionary
var locked_on_corrupt_file := false

func _init(storage_path: String = DEFAULT_PATH) -> void:
    path = storage_path
    state = _blank()

func _blank() -> Dictionary:
    return {"schema_version":SCHEMA_VERSION,"history":[],
        "presets":{},"settings":{"d100_mode":"pair","dice_skin":"obsidian",
        "table_skin":"black_velvet"}}

func _error(message: String) -> Dictionary:
    return {"ok":false,"error":message}

func snapshot() -> Dictionary:
    return state.duplicate(true)

func load_state() -> Dictionary:
    if not FileAccess.file_exists(path):
        state = _blank()
        locked_on_corrupt_file = false
        return {"ok":true,"created_default":true}
    var f := FileAccess.open(path,FileAccess.READ)
    if f == null:
        locked_on_corrupt_file = true
        return _error("Не удалось прочитать локальное хранилище")
    var decoded: Variant = JSON.parse_string(f.get_as_text())
    f.close()
    if typeof(decoded) != TYPE_DICTIONARY:
        locked_on_corrupt_file = true
        return _error("Повреждённый формат локального файла; содержимое сохранено")
    var obj: Dictionary = decoded
    if int(obj.get("schema_version",-1)) != SCHEMA_VERSION:
        locked_on_corrupt_file = true
        return _error("Неизвестная версия данных, автоматическое затирание запрещено")
    if typeof(obj.get("history")) != TYPE_ARRAY or typeof(obj.get("presets")) != TYPE_DICTIONARY or typeof(obj.get("settings")) != TYPE_DICTIONARY:
        locked_on_corrupt_file = true
        return _error("Некорректная структура данных, файл не перезаписан")
    if (obj["history"] as Array).size() > MAX_HISTORY or (obj["presets"] as Dictionary).size() > MAX_PRESETS:
        locked_on_corrupt_file = true
        return _error("Содержимое хранилища превышает допустимые пределы")
    state = obj.duplicate(true)
    locked_on_corrupt_file = false
    return {"ok":true,"created_default":false}

func _commit(next: Dictionary) -> Dictionary:
    if locked_on_corrupt_file:
        return _error("Хранилище повреждено: безопасная перезапись заблокирована")
    var tmp := path + ".tmp"
    var f := FileAccess.open(tmp,FileAccess.WRITE)
    if f == null:
        return _error("Не удалось создать временный локальный файл")
    f.store_string(JSON.stringify(next,"  ") + "\n")
    f.flush()
    f.close()
    var moved := DirAccess.rename_absolute(
        ProjectSettings.globalize_path(tmp), ProjectSettings.globalize_path(path))
    if moved != OK:
        return _error("Не удалось атомарно сохранить данные, старая версия не удалена")
    state = next
    return {"ok":true}

func append_physical_result(outcome: Dictionary) -> Dictionary:
    if not bool(outcome.get("ok",false)) or int(outcome.get("schema_version",-1)) != 1 or str(outcome.get("source","")) != "actual_physical_faces_required" or typeof(outcome.get("groups")) != TYPE_ARRAY:
        return _error("В историю нельзя записать непроверенный или придуманный бросок")
    # A string claiming physical provenance is not an integrity check.
    # Recompute the *entire* result from its stored face/reroll trace and
    # reject tampered totals, invalid D20 mode/crit or altered group records.
    var spec: Dictionary = Formula.parse(str(outcome.get("formula","")))
    if not bool(spec.get("ok",false)):
        return _error("Невозможно восстановить формулу записываемого броска")
    var observed: Array = []
    var selected_group := -1
    var output_groups: Array = outcome["groups"]
    for index in range(output_groups.size()):
        if typeof(output_groups[index]) != TYPE_DICTIONARY:
            return _error("Повреждённая трасса физического броска")
        var group: Dictionary = output_groups[index]
        if bool(group.get("selected_d20",false)):
            if selected_group >= 0:
                return _error("Несколько выбранных критических D20")
            selected_group = index
        if typeof(group.get("attempts")) != TYPE_ARRAY:
            return _error("Нет последовательности реальных граней")
        var saved_traces: Array = group["attempts"]
        var sources: Variant = group.get("percentile_source_d10_faces")
        if typeof(sources) != TYPE_ARRAY or sources.size() != saved_traces.size():
            return _error("Исходные грани процентного D100 не сохранены")
        var actual_group: Array = []
        for source_index in range(saved_traces.size()):
            var pair: Variant = sources[source_index]
            if typeof(pair) != TYPE_ARRAY:
                return _error("Повреждённая трасса исходных D10")
            if pair.size() == 2:
                actual_group.append({"tens":pair[0],"ones":pair[1]})
            elif pair.is_empty():
                actual_group.append(saved_traces[source_index])
            else:
                return _error("Повреждённая пара процентных граней")
        observed.append(actual_group)
    var verified: Dictionary = Formula.evaluate(spec, observed,
        str(outcome.get("d20_mode","normal")), selected_group)
    if not bool(verified.get("ok",false)) or verified.get("total") != outcome.get("total") or verified.get("natural_d20_critical") != outcome.get("natural_d20_critical") or verified.get("groups") != outcome.get("groups") or verified.get("modifier") != outcome.get("modifier"):
        return _error("Расчёт не совпадает с сохранёнными физическими гранями")
    var next := snapshot()
    var row := outcome.duplicate(true)
    row["timestamp_unix"] = Time.get_unix_time_from_system()
    var entries: Array = next["history"]
    entries.push_front(row)
    if entries.size() > MAX_HISTORY:
        entries.resize(MAX_HISTORY)
    return _commit(next)

func clear_history(confirmed: bool = false) -> Dictionary:
    if not confirmed:
        return _error("Очистка истории требует подтверждения")
    var next := snapshot()
    next["history"] = []
    return _commit(next)

func upsert_preset(title: String, expression: String,
        mode: String = "normal", d100_mode: String = "pair") -> Dictionary:
    var name := title.strip_edges()
    if name.is_empty() or name.length() > 40:
        return _error("Имя пресета должно содержать от 1 до 40 символов")
    var parsed: Dictionary = Formula.parse(expression)
    if not bool(parsed.get("ok",false)):
        return _error("Формула пресета недействительна")
    if not ["normal","advantage","disadvantage"].has(mode) or not ["single","pair"].has(d100_mode):
        return _error("Недопустимый режим пресета")
    if mode != "normal":
        var allowed := 0
        for group in parsed["groups"]:
            if int(group["sides"]) == 20 and int(group["count"]) == 1:
                allowed += 1
        if allowed != 1:
            return _error("Для преимущества нужен однозначно выбранный D20")
    var next := snapshot()
    var presets: Dictionary = next["presets"]
    if not presets.has(name) and presets.size() >= MAX_PRESETS:
        return _error("Достигнут предел количества пресетов")
    presets[name] = {"formula":parsed["formula"],"d20_mode":mode,
        "d100_mode":d100_mode}
    return _commit(next)

func delete_preset(name: String, confirmed: bool = false) -> Dictionary:
    if not confirmed:
        return _error("Удаление пресета требует подтверждения")
    var next := snapshot()
    var presets: Dictionary = next["presets"]
    if not presets.has(name):
        return _error("Такого пресета нет")
    presets.erase(name)
    return _commit(next)
