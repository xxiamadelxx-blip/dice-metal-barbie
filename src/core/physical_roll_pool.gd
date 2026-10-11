extends Node3D
## M4 real physical mixed-pool controller. Rolls ONE successive Jolt die at
## a time (two simultaneously for percentile D100). No fake outcomes.
## Does not change the existing M3 one-die controller or camera.
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
const MAX_PHYSICAL_STEPS := 2400
var busy := false
var last_result: Dictionary = {}
var dice_spawned := 0
var physics_completed := 0
var last_physical_error := ""
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
    var spec := Formula.parse(expression)
    if not bool(spec.get("ok",false)):
        pool_failed.emit(str(spec.get("error","Формула недействительна")))
        return false
    if not ["normal","advantage","disadvantage"].has(mode) or not ["pair","single"].has(percentile_mode):
        pool_failed.emit("Недопустимый режим составного броска")
        return false
    # Render/physics safety: limit a complete pool to 8 single source dice
    # plus the required two D20 or two D10 percentile bodies.
    if int(spec["physical_dice"]) > 8:
        pool_failed.emit("Слишком много кубиков для физического стола")
        return false
    _spec = spec
    _mode = mode
    _percentile_mode = percentile_mode
    _chosen_d20 = selected_d20_group
    _failed_message = ""
    last_physical_error = ""
    _values.clear()
    last_result = {}
    dice_spawned = 0
    physics_completed = 0
    busy = true
    call_deferred("_run")
    return true

func _make_die(sides: int) -> RigidBody3D:
    var result: RigidBody3D
    match sides:
        4:
            result = D4.new()
        6:
            result = D6.new()
        8:
            result = D8.new()
        12:
            result = D12.new()
        20:
            result = D20.new()
        10,100:
            result = Trapezohedron.new()
            result.set("sides", sides)
    return result

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
            return Kite.top_value(sides, basis)
        12:
            return Dodeca.top_value(basis)
        20:
            return Ico.top_value(basis)
    return -1

func _on_die_completed(value: int, body: RigidBody3D) -> void:
    if busy and is_instance_valid(body):
        _values[body.get_instance_id()] = value
        physics_completed += 1

func _on_die_failed(message: String, body: RigidBody3D) -> void:
    if busy:
        _failed_message = "Физический кубик %s: %s" % [body.name,message]

func _remove_active() -> void:
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

func _start_body(sides: int, lane: int) -> RigidBody3D:
    var body := _make_die(sides)
    if body == null:
        return null
    # Must not reuse a name that Godot may still be queue_free-ing.
    dice_spawned += 1
    body.name = "M4_D%d_%d" % [sides,dice_spawned]
    add_child(body)
    _active.append(body)
    body.connect("roll_completed",Callable(self,"_on_die_completed").bind(body))
    body.connect("roll_failed",Callable(self,"_on_die_failed").bind(body))
    if sides == 10:
        body.call("throw_from_top",lane)
    else:
        body.call("throw_from_top")
    return body

func _wait_for_source() -> bool:
    for tick in range(MAX_PHYSICAL_STEPS):
        await get_tree().physics_frame
        if not _failed_message.is_empty():
            return false
        var ready := true
        for body in _active:
            if not is_instance_valid(body) or not _values.has(body.get_instance_id()):
                ready = false
        if ready:
            return true
    _failed_message = "Физические кубики не остановились за лимит времени"
    return false

func _collect(sides: int, pair: bool) -> Variant:
    _remove_active()
    _values.clear()
    if pair:
        var tens := _start_body(10,-1)
        var ones := _start_body(10,1)
        if tens == null or ones == null:
            _failed_message = "Невозможно создать пару физических D10"
            return null
    else:
        if _start_body(sides,0) == null:
            _failed_message = "Невозможно создать физический кубик D%d" % sides
            return null
    if not await _wait_for_source():
        return null
    var real_faces: Array[int] = []
    for body in _active:
        var actual_sides := 10 if pair else sides
        var top := _actual_top(body,actual_sides)
        var reported := int(_values.get(body.get_instance_id(),-1))
        # Independently compare the physical upper face, signal result,
        # body's own result and genuinely sleeping rigid body.
        if top < 1 or top != reported or top != int(body.get("result")) or not body.sleeping:
            _failed_message = "Несовпадение грани и результата физического D%d" % actual_sides
            return null
        real_faces.append(top)
    if pair:
        return {"tens":real_faces[0],"ones":real_faces[1]}
    return real_faces[0]

func _run() -> void:
    # Do not overwrite any original M3 die. This controller is a separate
    # child under the same physical rails and velvet floor.
    var groups: Array = _spec.get("groups",[])
    var observed: Array = []
    var eligible: Array[int] = []
    for i in range(groups.size()):
        if int(groups[i]["sides"]) == 20 and int(groups[i]["count"]) == 1:
            eligible.append(i)
    var chosen := _chosen_d20
    if chosen < 0 and eligible.size() == 1:
        chosen = eligible[0]
    if _mode != "normal" and not eligible.has(chosen):
        _abort("Преимущество требует единственный выбранный D20")
        return
    for i in range(groups.size()):
        var group: Dictionary = groups[i]
        var sides := int(group["sides"])
        var amount := int(group["count"])
        if i == chosen and _mode != "normal":
            amount = 2
        var observations: Array = []
        for index in range(amount):
            var physical: Variant = await _collect(sides,
                sides == 100 and _percentile_mode == "pair")
            if physical == null:
                _abort(_failed_message)
                return
            observations.append(physical)
            # Every individual successful body is truly physically completed
            # before proceeding; late signals cannot modify a later roll.
            await get_tree().process_frame
        observed.append(observations)
    var final := Formula.evaluate(_spec,observed,_mode,chosen)
    if not bool(final.get("ok",false)):
        _abort(str(final.get("error","Ошибка подсчёта физических результатов")))
        return
    # Leave the final physical die(s) visible on the table. Actual
    # chronological observations live in the structured completed result.
    last_result = final
    busy = false
    pool_completed.emit(final)
