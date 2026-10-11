extends Node3D
## M4: a real simultaneous multi-die tabletop throw with persistent final pile.
## Actual Jolt sleeping upper faces determine EVERY value; no outcome injection.
signal pool_completed(result: Dictionary)
signal pool_failed(reason: String)

const Formula = preload("res://src/core/roll_formula.gd")
const D4 = preload("res://src/dice/d4_body.gd")
const D6 = preload("res://src/dice/d6_body.gd")
const D8 = preload("res://src/dice/d8_body.gd")
const D12 = preload("res://src/dice/d12_body.gd")
const D20 = preload("res://src/dice/d20_body.gd")
const Trapezohedron = preload("res://src/dice/trapezohedron_body.gd")
const Tetra = preload("res://src/core/tetrahedron.gd")
const Cube = preload("res://src/core/cube_symmetry.gd")
const Octa = preload("res://src/core/octahedron.gd")
const Dodeca = preload("res://src/core/dodecahedron.gd")
const Ico = preload("res://src/core/icosahedron.gd")
const Kite = preload("res://src/core/trapezohedron.gd")
const CriticalAura = preload("res://src/visual/critical_aura.gd")
const MAX_PHYSICAL_STEPS := 2400
const MAX_VISIBLE_BODIES := 8
const LAUNCH_COLUMNS := 3
const LAUNCH_SPACING_X := 1.75
const LAUNCH_SPACING_Z := 1.85

var busy := false
var last_result: Dictionary = {}
var dice_spawned := 0
var physics_completed := 0
var last_physical_error := ""
var peak_simultaneously_rolling := 0
var _spec: Dictionary = {}
var _mode := "normal"
var _percentile_mode := "pair"
var _chosen_d20 := -1
var _active: Array[RigidBody3D] = []
var _values: Dictionary = {}
var _failed_message := ""

func begin(expression: String, mode: String = "normal",
        percentile_mode: String = "pair", selected_d20_group: int = -1) -> bool:
    if busy:
        return false
    var spec: Dictionary = Formula.parse(expression)
    if not bool(spec.get("ok",false)):
        pool_failed.emit(str(spec.get("error","Формула недействительна")))
        return false
    if not ["normal","advantage","disadvantage"].has(mode) or not ["pair","single"].has(percentile_mode):
        pool_failed.emit("Недопустимый режим составного броска")
        return false
    # Validate ALL physical bodies (not just logical D100=1 dice) before
    # replacing the old valid physical pile.
    var eligible: Array[int] = []
    for i in range((spec["groups"] as Array).size()):
        var g: Dictionary = spec["groups"][i]
        if int(g["sides"]) == 20 and int(g["count"]) == 1:
            eligible.append(i)
    var chosen := selected_d20_group
    if chosen == -1 and eligible.size() == 1:
        chosen = eligible[0]
    if selected_d20_group >= 0 and not eligible.has(selected_d20_group):
        pool_failed.emit("Указана недопустимая группа D20")
        return false
    if mode != "normal" and (chosen < 0 or not eligible.has(chosen)):
        pool_failed.emit("Для преимущества выберите единственный D20")
        return false
    var required := 0
    for i in range((spec["groups"] as Array).size()):
        var group: Dictionary = spec["groups"][i]
        var amount: int = 2 if i == chosen and mode != "normal" else int(group["count"])
        var source_dice := 2 if int(group["sides"]) == 100 and percentile_mode == "pair" else 1
        required += amount * source_dice
    if required > MAX_VISIBLE_BODIES:
        pool_failed.emit("На столе одновременно доступно до %d физических кубиков" % MAX_VISIBLE_BODIES)
        return false
    if required == 0:
        pool_failed.emit("Для броска необходим хотя бы один физический кубик")
        return false
    _spec = spec
    _mode = mode
    _percentile_mode = percentile_mode
    _chosen_d20 = chosen
    _remove_active()
    _failed_message = ""
    last_physical_error = ""
    _values.clear()
    last_result = {}
    dice_spawned = 0
    physics_completed = 0
    peak_simultaneously_rolling = 0
    busy = true
    call_deferred("_run")
    return true

func _make_die(sides: int) -> RigidBody3D:
    var die: RigidBody3D
    match sides:
        4:
            die = D4.new()
        6:
            die = D6.new()
        8:
            die = D8.new()
        12:
            die = D12.new()
        20:
            die = D20.new()
        10,100:
            die = Trapezohedron.new()
            die.set("sides",sides)
    return die

func _actual_top(body: RigidBody3D, sides: int) -> int:
    var basis: Basis = body.global_transform.basis.orthonormalized()
    match sides:
        4:
            return Tetra.top_value(basis)
        6:
            return Cube.top_value(basis)
        8:
            return Octa.top_value(basis)
        10,100:
            return Kite.top_value(sides,basis)
        12:
            return Dodeca.top_value(basis)
        20:
            return Ico.top_value(basis)
    return -1

func _on_die_completed(value: int, body: RigidBody3D) -> void:
    if busy and is_instance_valid(body) and not _values.has(body.get_instance_id()):
        _values[body.get_instance_id()] = value
        physics_completed += 1

func _on_die_failed(message: String, body: RigidBody3D) -> void:
    if busy:
        _failed_message = "Физический кубик %s: %s" % [body.name,message]

func _remove_active() -> void:
    # Godot queue_free() is deferred. Detach synchronously so old Jolt
    # colliders never obstruct the next simultaneous physical cast.
    for body in _active:
        if is_instance_valid(body):
            if body.get_parent() == self:
                remove_child(body)
            body.queue_free()
    _active.clear()

func _abort(reason: String) -> void:
    if not busy:
        return
    last_physical_error = reason
    busy = false
    _remove_active()
    pool_failed.emit(reason)

func _launch_position(slot: int) -> Vector2:
    # 3 columns * up to 3 rows. Adjacent convex bodies are separated at
    # launch, remain within the exact table rails, and then interact in Jolt.
    var col: int = slot % LAUNCH_COLUMNS
    var row: int = int(slot / LAUNCH_COLUMNS)
    return Vector2((float(col)-1.0)*LAUNCH_SPACING_X,
        -3.5 + float(row)*LAUNCH_SPACING_Z)

func _start_body(sides: int, slot: int) -> RigidBody3D:
    var body := _make_die(sides)
    if body == null:
        _failed_message = "Неизвестная физическая геометрия D%d" % sides
        return null
    dice_spawned += 1
    body.name = "M4_D%d_%d" % [sides,dice_spawned]
    add_child(body)
    _active.append(body)
    body.connect("roll_completed",Callable(self,"_on_die_completed").bind(body))
    body.connect("roll_failed",Callable(self,"_on_die_failed").bind(body))
    if sides == 10:
        body.call("throw_from_top",0)
    else:
        body.call("throw_from_top")
    # All launches happen in the same frame, BEFORE any physics tick. The
    # native throw_from_top supplied an authentic random rotation, impulse
    # and torque; change only collision-safe initial throw POSITION, never
    # the chosen orientation or eventual result.
    var lane := _launch_position(slot)
    body.position = Vector3(lane.x,body.position.y,lane.y)
    return body

func _wait_for_all_real_faces() -> bool:
    for tick in range(MAX_PHYSICAL_STEPS):
        await get_tree().physics_frame
        if not _failed_message.is_empty():
            return false
        var moving := 0
        for body in _active:
            if is_instance_valid(body) and bool(body.get("rolling")):
                moving += 1
        peak_simultaneously_rolling = maxi(peak_simultaneously_rolling,moving)
        if _values.size() == _active.size():
            # Body may be woken by another COLLISION after it reported the
            # first sleep. Only accept final state after every die settled.
            var all_settled := true
            for body in _active:
                if not is_instance_valid(body) or not body.sleeping:
                    all_settled = false
                    break
            if all_settled:
                return true
    _failed_message = "Не все физические кубики остановились за допустимое время"
    return false

func _run() -> void:
    var groups: Array = _spec.get("groups",[])
    var plan: Array[Dictionary] = []
    var observed: Array = []
    for i in range(groups.size()):
        var group: Dictionary = groups[i]
        var n: int = 2 if i == _chosen_d20 and _mode != "normal" else int(group["count"])
        var sides: int = int(group["sides"])
        var sources: Array = []
        for logical_index in range(n):
            sources.append(null)
            if sides == 100 and _percentile_mode == "pair":
                plan.append({"group":i,"index":logical_index,"sides":10,"digit":"tens"})
                plan.append({"group":i,"index":logical_index,"sides":10,"digit":"ones"})
            else:
                plan.append({"group":i,"index":logical_index,"sides":sides,"digit":""})
        observed.append(sources)
    if plan.is_empty() or plan.size() > MAX_VISIBLE_BODIES:
        _abort("Некорректная физическая конфигурация броска")
        return
    for slot in range(plan.size()):
        if _start_body(int(plan[slot]["sides"]),slot) == null or not _failed_message.is_empty():
            _abort(_failed_message)
            return
    # Every physical body is already in the scene at the start of the FIRST
    # physics tick. Nothing is removed until a NEW roll or a real failure.
    if OS.is_debug_build():
        print("DICE_M4_SIMULTANEOUS_STARTED=%d" % _active.size())
    if not await _wait_for_all_real_faces():
        _abort(_failed_message)
        return
    if physics_completed != plan.size():
        _abort("Не получен каждый сигнал завершения физического Jolt")
        return
    for slot in range(plan.size()):
        var body: RigidBody3D = _active[slot]
        var source: Dictionary = plan[slot]
        var sides: int = int(source["sides"])
        var top := _actual_top(body,sides)
        var signal_face := int(_values.get(body.get_instance_id(),-1))
        if top < 1 or top != signal_face or top != int(body.get("result")) or not body.sleeping:
            _abort("Физический результат изменился после столкновения: D%d" % sides)
            return
        var gi: int = int(source["group"])
        var di: int = int(source["index"])
        var items: Array = observed[gi]
        var digit: String = str(source["digit"])
        if digit.is_empty():
            items[di] = top
        else:
            var current: Dictionary = items[di] if typeof(items[di]) == TYPE_DICTIONARY else {}
            current[digit] = top
            items[di] = current
    var result: Dictionary = Formula.evaluate(_spec,observed,_mode,_chosen_d20)
    if not bool(result.get("ok",false)):
        _abort(str(result.get("error","Невозможно вычислить реальные грани")))
        return
    # Critical effects follow only the *selected, unmodified, physically
    # settled D20*, never a dice pool total or unchosen advantage die.
    # This retains the approved die-origin aura rather than a fake HUD glow.
    var critical: String = str(result.get("natural_d20_critical","none"))
    if _chosen_d20 >= 0 and ["success","failure"].has(critical):
        var crit_group: Dictionary = result["groups"][_chosen_d20]
        var selected_faces: Array = crit_group.get("kept_faces",[])
        if selected_faces.size() == 1:
            var selected_value: int = int(selected_faces[0])
            for slot in range(plan.size()):
                if int(plan[slot]["group"]) != _chosen_d20 or int(plan[slot]["sides"]) != 20:
                    continue
                var physical_d20: RigidBody3D = _active[slot]
                if int(physical_d20.get("result")) == selected_value:
                    CriticalAura.spawn(physical_d20,20,selected_value)
                    break
    result["physical_bodies"] = plan.size()
    result["peak_simultaneously_rolling"] = peak_simultaneously_rolling
    result["all_source_bodies_remain_visible"] = true
    # Keep all REAL settled rigid bodies visible, with their original Jolt
    # collision hulls, poses, and recorded result, until the next cast.
    last_result = result
    busy = false
    if OS.is_debug_build():
        print("DICE_M4_SIMULTANEOUS_COMPLETED=%d" % _active.size())
    pool_completed.emit(result)
