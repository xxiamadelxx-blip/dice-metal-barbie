extends SceneTree
## Deterministic oracle of actual-source face arithmetic, then genuine user://
## persistence. Source values here are fixtures ONLY, not claimed Jolt throws.
const Formula = preload("res://src/core/roll_formula.gd")
const Store = preload("res://src/core/roll_persistence.gd")
const History = preload("res://src/ui/m4_history_dialog.gd")
const FILE := "user://m4_percentile_reroll_qa.json"
var checks := 0
var errors := 0
func _initialize() -> void:
    call_deferred("_run")
func _assert(cond: bool, label: String) -> void:
    checks += 1
    if not cond:
        errors += 1
        push_error(label)
func _run() -> void:
    var spec := Formula.parse("2d100+1d4-2")
    var original := Formula.evaluate(spec,[
        [{"tens":10,"ones":10},{"tens":3,"ones":8}],[4]])
    _assert(original.get("ok",false) and original.get("total") == 140,
        "Original 100 + 38 + 4 - 2 must be 140")
    var rerolled := Formula.evaluate(spec,[
        [{"percentile_attempts":[
            {"tens":10,"ones":10},{"tens":6,"ones":1}]},
            {"tens":3,"ones":8}],[4]])
    _assert(rerolled.get("ok",false) and int(rerolled.get("total",0))==101,
        "Physical percentile pair 100→61, other pair 38 and D4 4 => 101")
    if bool(rerolled.get("ok",false)):
        _assert(rerolled["groups"][0]["attempts"][0] == [100,61],
            "Both original and rerolled percentile D100 sums must survive")
        _assert(rerolled["groups"][0]["percentile_source_d10_faces"][0] ==
            [[10,10],[6,1]], "Both ORIGINAL pairs of actual D10 source faces missing")
        _assert(rerolled["groups"][0]["percentile_source_d10_faces"][1] == [3,8],
            "Other logical percentile die must not lose its initial source digits")
    var second_round := Formula.evaluate(Formula.parse("1d100"),[
        [{"percentile_attempts":[{"tens":10,"ones":10},
            {"tens":6,"ones":1},{"tens":10,"ones":10}]}]])
    _assert(second_round.get("ok",false) and second_round.get("total")==100,
        "Repeated genuine percentile reroll history must end at 100, not 0")
    _assert(not Formula.evaluate(Formula.parse("1d100"),[
        [{"percentile_attempts":[{"tens":10,"ones":10},
            {"tens":0,"ones":1}]}]]).get("ok",false),
        "Percentile pair with a fake physical face zero must be refused")
    _assert(not Formula.evaluate(Formula.parse("1d100"),[
        [{"percentile_attempts":[]}]]).get("ok",false),
        "Empty real percentile rethrow series must fail")
    _assert(not Formula.evaluate(Formula.parse("1d100"),[
        [{"percentile_attempts":[{"tens":2}]}]]).get("ok",false),
        "Lost ones-digit source must fail")
    if FileAccess.file_exists(FILE):
        DirAccess.remove_absolute(ProjectSettings.globalize_path(FILE))
    var store := Store.new(FILE)
    _assert(store.load_state().get("ok",false),"Offline percentile test store read failed")
    _assert(store.append_physical_result(original).get("ok",false),
        "Old one-throw D100 format must remain writable")
    _assert(store.append_physical_result(rerolled).get("ok",false),
        "New full physical pair history must pass independent store validation")
    var broken := rerolled.duplicate(true)
    broken["groups"][0]["percentile_source_d10_faces"][0][1]=[2,1]
    _assert(not store.append_physical_result(broken).get("ok",false),
        "Tampered historical pair MUST be refused even when final sum looks correct")
    var broken_sum := rerolled.duplicate(true)
    broken_sum["total"]=999
    _assert(not store.append_physical_result(broken_sum).get("ok",false),
        "Tampered stored physical D100 total must be refused")
    var restarted := Store.new(FILE)
    _assert(restarted.load_state().get("ok",false),"Real user:// data did not reopen")
    var saved: Array = restarted.snapshot()["history"]
    _assert(saved.size()==2 and int(saved[0]["total"])==101,
        "Percentile pair reroll disappeared after local data relaunch")
    if saved.size()>0:
        var pairs: Array = saved[0]["groups"][0]["percentile_source_d10_faces"][0]
        _assert(pairs.size()==2 and int(pairs[0][0])==10 and
            int(pairs[1][0])==6, "Nested original and new digits not persisted intact")
    # UI must show BOTH pairs in user-facing history drill-down, not '[10,10]'.
    var view := History.new()
    root.add_child(view)
    await process_frame
    view.set_history(saved)
    var text_area := view.find_child("ActualIndividualFacesAndRerolls",true,false) as RichTextLabel
    print("M4_D100_HISTORY_RENDERED_DETAIL=",text_area.text if text_area != null else "(missing RichTextLabel)")
    _assert(text_area!=null and text_area.text.contains("10/10 → 6/1"),
        "Real user history must explain BOTH physical percentile pairs")
    view.queue_free()
    if FileAccess.file_exists(FILE):
        DirAccess.remove_absolute(ProjectSettings.globalize_path(FILE))
    print("M4_PERCENTILE_PERSISTED_REROLL checks=%d errors=%d" % [checks,errors])
    quit(0 if errors==0 else 1)
