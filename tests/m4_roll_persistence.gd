extends SceneTree
## Real user:// disk writes in an isolated test filename, never app data.
const Store = preload("res://src/core/roll_persistence.gd")
const Formula = preload("res://src/core/roll_formula.gd")
const TEMP := "user://m4_persistence_qa.json"
var checks := 0
var errors := 0

func _initialize() -> void:
    call_deferred("_run")

func _assert(ok: bool, message: String) -> void:
    checks += 1
    if not ok:
        errors += 1
        push_error(message)

func _run() -> void:
    var abs_path := ProjectSettings.globalize_path(TEMP)
    if FileAccess.file_exists(TEMP):
        DirAccess.remove_absolute(abs_path)
    var first := Store.new(TEMP)
    _assert(first.load_state().get("created_default",false),
        "First load must start from a local offline default state")
    _assert(not first.clear_history().get("ok",false),
        "History may not be cleared without confirmation")
    _assert(not first.append_physical_result({"ok":true}).get("ok",false),
        "Unverified synthetic result must never be saved")
    var observed := Formula.evaluate(Formula.parse("2d6+1d20-3"),
        [[6,2],[20]])
    _assert(observed.get("ok",false),"Physical trace fixture invalid")
    var forged := observed.duplicate(true)
    forged["total"] = 999
    _assert(not first.append_physical_result(forged).get("ok",false),
        "Tampered nonphysical sum must never be persisted")
    var altered_face := observed.duplicate(true)
    altered_face["groups"][0]["attempts"][0] = [42]
    _assert(not first.append_physical_result(altered_face).get("ok",false),
        "Physically impossible face must never be persisted")
    _assert(first.append_physical_result(observed).get("ok",false),
        "Actual physical trace failed to persist")
    var pair := Formula.evaluate(Formula.parse("1d100"),
        [[{"tens":10,"ones":10}]])
    _assert(first.append_physical_result(pair).get("ok",false),
        "Real paired-percentile source faces were not saved offline")
    var altered_digits := pair.duplicate(true)
    altered_digits["groups"][0]["percentile_source_d10_faces"][0] = [2,1]
    _assert(not first.append_physical_result(altered_digits).get("ok",false),
        "Tampered D100 pair digits must not survive storage integrity recheck")
    _assert(first.upsert_preset("Атака босса","2d6+1d20-3").get("ok",false),
        "Named offline preset failed")
    _assert(first.upsert_preset("Атака босса","1d20+7","advantage").get("ok",false),
        "Editing existing named preset failed")
    _assert(not first.upsert_preset("bad","1d37").get("ok",false),
        "Unsupported physical die must be rejected in preset")
    _assert(not first.upsert_preset("invalid","1d6","advantage").get("ok",false),
        "D20-only advantage contract violated")
    var restarted := Store.new(TEMP)
    _assert(restarted.load_state().get("ok",false),
        "Versioned offline data failed to reload after relaunch")
    var saved := restarted.snapshot()
    _assert((saved["history"] as Array).size() == 2,
        "Physical and percentile history entries were lost after relaunch")
    # JSON.parse_string restores untyped nested arrays; check the actual
    # numeric physical face values, not Array[T] identity/equality semantics.
    var loaded_pairs: Array = saved["history"][0]["groups"][0]["percentile_source_d10_faces"]
    var source_digits_preserved := false
    if loaded_pairs.size() == 1 and typeof(loaded_pairs[0]) == TYPE_ARRAY:
        var digits: Array = loaded_pairs[0]
        source_digits_preserved = digits.size() == 2 and int(digits[0]) == 10 and int(digits[1]) == 10
    _assert(int(saved["history"][0]["total"]) == 100 and source_digits_preserved,
        "Persisted D100 raw faces wrong: " + JSON.stringify(saved["history"][0]))
    _assert(saved["history"][1]["total"] == 25,
        "Saved Jolt-derived mixed-pool result was altered")
    _assert(saved["presets"]["Атака босса"]["formula"] == "1d20+7",
        "Edited named preset not persisted")
    _assert(not restarted.delete_preset("Атака босса").get("ok",false),
        "Preset deletion must demand confirmation")
    _assert(restarted.delete_preset("Атака босса",true).get("ok",false),
        "Confirmed deletion of preset failed")
    _assert(not restarted.clear_history().get("ok",false),
        "Unconfirmed history clear must not erase history")
    _assert(restarted.clear_history(true).get("ok",false),
        "Confirmed history deletion failed")
    var third := Store.new(TEMP)
    _assert(third.load_state().get("ok",false),
        "Persisted cleared state cannot reload")
    _assert((third.snapshot()["history"] as Array).is_empty(),
        "Confirmed history erase not persisted")
    var f := FileAccess.open(TEMP,FileAccess.WRITE)
    f.store_string("{\"schema_version\":999,\"history\":[]}")
    f.close()
    var corrupt := Store.new(TEMP)
    _assert(not corrupt.load_state().get("ok",false),
        "Unknown schema must reject read without destructive auto-migration")
    _assert(not corrupt.upsert_preset("test","1d6").get("ok",false),
        "Corrupted user file must not be overwritten")
    var unchanged := FileAccess.get_file_as_string(TEMP)
    _assert(unchanged.contains("\"schema_version\":999"),
        "Error recovery must not overwrite original corrupted file")
    if FileAccess.file_exists(TEMP):
        DirAccess.remove_absolute(abs_path)
    print("M4 offline versioned persistence: %d checks, %d errors" % [checks,errors])
    quit(0 if errors == 0 else 1)
