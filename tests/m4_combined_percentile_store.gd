extends SceneTree
## Oracle fixtures only: Jolt physics proof is in separate actual scene test.
const F = preload("res://src/core/roll_formula.gd")
const S = preload("res://src/core/roll_persistence.gd")
const H = preload("res://src/ui/m4_history_dialog.gd")
const FILE := "user://m4_both_and_one_percentile_qa.json"
var checks := 0
var fails := 0
func _initialize() -> void:
    call_deferred("_run")
func ck(v: bool,why: String) -> void:
    checks += 1
    if not v:
        fails += 1
        push_error(why)
func _run() -> void:
    var spec := F.parse("2d100+1d4-2")
    var original := F.evaluate(spec,[[{"tens":10,"ones":10},
        {"tens":3,"ones":8}],[4]])
    ck(original.get("ok",false) and original["total"]==140,
        "Original D100=100+38+4-2 wrong")
    var combined := F.evaluate(spec,[[{"states":[[10,10],[6,1]],
        "kinds":["both"]},{"tens":3,"ones":8}],[4]])
    ck(combined.get("ok",false) and combined.get("total")==101,
        "True two-body rethrow must yield 61+38+4-2=101")
    if combined.get("ok",false):
        var group: Dictionary = combined["groups"][0]
        ck(group["attempts"][0]==[100,61],
            "Original and new physical D100 values missing")
        ck(group["percentile_source_d10_attempts"][0]==[[10,10],[6,1]],
            "Both ORIGINAL and repeated raw D10 upper pairs missing")
        ck(group["percentile_source_d10_faces"][0]==[6,1] and
            group["percentile_source_d10_faces"][1]==[3,8],
            "Independent second D100 changed without physical selection")
        ck(group["percentile_reroll_modes"][0]==["both"],
            "Cannot distinguish FULL-pair reroll from one-digit reroll")
    ck(not F.evaluate(F.parse("1d100"),[[
        {"states":[[10,10],[6,1]]}]]).get("ok",false),
        "Two digits changed without explicit BOTH metadata was accepted")
    var after_single := F.evaluate(F.parse("1d100"),[[
        {"states":[[10,10],[6,1],[6,5]],"kinds":["both","one"]}]])
    ck(after_single.get("ok",false) and after_single.get("total")==65,
        "Ordinary one-digit reroll after two-die reroll must remain supported")
    ck(not F.evaluate(F.parse("1d100"),[[
        {"states":[[10,10],[6,1],[2,7]],"kinds":["both","one"]}]])
        .get("ok",false), "An explicit single-digit action cannot edit both actual D10")
    ck(not F.evaluate(F.parse("1d100"),[[
        {"states":[[10,10],[0,1]],"kinds":["both"]}]])
        .get("ok",false), "Impossible real physical D10 face zero must fail")
    if FileAccess.file_exists(FILE):
        DirAccess.remove_absolute(ProjectSettings.globalize_path(FILE))
    var store := S.new(FILE)
    ck(store.load_state().get("ok",false),"Offline QA store could not initialize")
    ck(store.append_physical_result(original).get("ok",false),
        "Unchanged old one-throw format must remain writeable")
    ck(store.append_physical_result(combined).get("ok",false),
        "New two-die pair trace rejected by independent persistence validator")
    ck(store.append_physical_result(after_single).get("ok",false),
        "Existing one-digit reroll after both bodies reroll cannot persist")
    var tampered := combined.duplicate(true)
    tampered["groups"][0]["percentile_source_d10_attempts"][0][0]=[2,1]
    ck(not store.append_physical_result(tampered).get("ok",false),
        "Altered OLD source faces must not be silently accepted")
    var fake_mode := combined.duplicate(true)
    fake_mode["groups"][0]["percentile_reroll_modes"][0]=["one"]
    ck(not store.append_physical_result(fake_mode).get("ok",false),
        "Two-changed-digit history falsely marked ONE must fail")
    var reopened := S.new(FILE)
    ck(reopened.load_state().get("ok",false),"JSON data not retained on restart")
    var all: Array = reopened.snapshot()["history"]
    ck(all.size()==3 and int(all[1]["total"])==101,
        "Both physical D100 modes not retained in local history")
    var viewer := H.new()
    root.add_child(viewer)
    await process_frame
    viewer.set_history(all)
    var details := viewer.find_child("ActualIndividualFacesAndRerolls",true,false) as RichTextLabel
    # Newest result is the third (both THEN individual).
    ck(details!=null and details.text.contains("10/10 → 6/1 → 6/5"),
        "Readable history hides original, both and one-digit source pairs")
    viewer.queue_free()
    if FileAccess.file_exists(FILE):
        DirAccess.remove_absolute(ProjectSettings.globalize_path(FILE))
    print("M4_BOTH_PLUS_SINGLE_PERCENTILE_STORE checks=%d fails=%d" %
        [checks,fails])
    quit(0 if fails==0 else 1)
