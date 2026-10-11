extends SceneTree
## M4 deterministic oracle fixtures; these numbers are TEST INPUTS, not
## synthesized real Jolt rolls. Runtime must supply actual observed faces.
const Formula = preload("res://src/core/roll_formula.gd")
var checks := 0
var failed := 0

func _initialize() -> void:
    call_deferred("_run")

func check(ok: bool, message: String) -> void:
    checks += 1
    if not ok:
        failed += 1
        push_error(message)

func _run() -> void:
    var p := Formula.parse("2d6 + 1d20 - 3")
    check(p.get("ok",false), "Mixed-pool parsing failed")
    if p.get("ok",false):
        check(p["modifier"] == -3 and p["physical_dice"] == 3,
            "Parsed count and modifier wrong")
        var roll := Formula.evaluate(p,[[6,2],[20]])
        check(roll.get("ok",false) and roll["total"] == 25,
            "Mixed pool total must use supplied faces and modifier")
        check(roll.get("natural_d20_critical") == "success",
            "Crit must use the selected raw D20 face")
        check(roll["groups"][0]["kept_faces"] == [6,2],
            "Mixed pool must preserve actual individual physical outcomes")
    var signed := Formula.evaluate(Formula.parse("2d8-1d4-5"),[[8,2],[3]])
    check(signed.get("ok",false) and signed["total"] == 2,
        "Negative dice group arithmetic was lost")
    var normal := Formula.evaluate(Formula.parse("1d20+1d4+2"),[[5],[4]])
    check(normal.get("ok",false) and normal["total"] == 11,
        "Normal selected D20 plus modifier incorrect")
    var adv := Formula.evaluate(Formula.parse("1d20+1d4+2"),[[3,18],[4]],
        "advantage")
    check(adv.get("ok",false) and adv["total"] == 24,
        "Real two-D20 advantage must keep the larger face")
    check(adv.get("natural_d20_critical") == "none",
        "Modifier and unkept D20 may not create critical effects")
    var dis := Formula.evaluate(Formula.parse("1d20+1d4+2"),[[3,18],[4]],
        "disadvantage")
    check(dis.get("ok",false) and dis["total"] == 9,
        "D20 disadvantage must keep the smaller actual face")
    var a20 := Formula.evaluate(Formula.parse("1d20+7"),[[1,20]],
        "advantage")
    check(a20.get("natural_d20_critical") == "success" and a20["total"] == 27,
        "Selected natural 20 must crit independently of +7")
    var a1 := Formula.evaluate(Formula.parse("1d20+7"),[[1,20]],
        "disadvantage")
    check(a1.get("natural_d20_critical") == "failure" and a1["total"] == 8,
        "Selected natural 1 must fail independently of +7")
    var ambiguous := Formula.evaluate(Formula.parse("1d20+1d20"),[[20],[1]])
    check(ambiguous.get("natural_d20_critical") == "none",
        "Two D20 groups require an explicitly selected crit group")
    var explicit := Formula.evaluate(Formula.parse("1d20+1d20"),[[20],[1]],
        "normal",1)
    check(explicit.get("natural_d20_critical") == "failure",
        "Explicit selected second D20 must have natural-1 crit")
    check(not Formula.evaluate(Formula.parse("1d20+1d20"),[[20],[1]],
        "advantage").get("ok",false),
        "Advantage must refuse ambiguous unselected D20 groups")
    var reroll := Formula.evaluate(Formula.parse("2d6"),[[[1,6],[2]]])
    check(reroll.get("ok",false) and reroll["total"] == 8,
        "Recorded physical reroll must preserve both faces and use final face")
    check(reroll["groups"][0]["attempts"] == [[1,6],[2]],
        "Reroll history must keep every actually supplied face")
    var hundred := Formula.evaluate(Formula.parse("1d100"),[[100]])
    check(hundred.get("ok",false) and hundred["total"] == 100,
        "Physical single D100 value 100 must not be turned into 0")
    var pair := Formula.evaluate(Formula.parse("1d100"),
        [[{"tens":10,"ones":10}]])
    check(pair.get("ok",false) and pair["total"] == 100,
        "Two genuinely observed D10 zero digits must produce percentile 100")
    check(pair["groups"][0]["percentile_source_d10_faces"] == [[10,10]],
        "Percentile outcome must preserve both independent actual D10 faces")
    var digit_reroll := Formula.evaluate(Formula.parse("1d100"),
        [[{"states":[[4,1],[8,1],[8,10]]}]])
    check(digit_reroll.get("ok",false) and int(digit_reroll.get("total",0))==80,
        "Selective pair reroll must compute genuine final percentile 80")
    if digit_reroll.get("ok",false):
        check(digit_reroll["groups"][0]["attempts"][0]==[41,81,80],
            "Original and intermediate physical percentile values lost")
        check(digit_reroll["groups"][0]["percentile_source_d10_attempts"][0]==
            [[4,1],[8,1],[8,10]],"Source digit chronology dropped")
    check(not Formula.evaluate(Formula.parse("1d100"),
        [[{"states":[[2,2],[3,3]]}]]).get("ok",false),
        "One D10 reroll cannot modify both source bodies")
    var pair_61 := Formula.evaluate(Formula.parse("1d100"),
        [[{"tens":6,"ones":1}]])
    check(pair_61.get("ok",false) and pair_61["total"] == 61,
        "6 tens + 1 ones must produce physical percentile 61")
    check(not Formula.evaluate(Formula.parse("1d100"),
        [[{"tens":0,"ones":1}]]).get("ok",false),
        "Physical D10 face zero is invalid: printed zero is face 10")
    for bad in ["","1d20+","2d6++3","2d37","0d20","65d6","3d7",
        "1d20 1d6","d0","d6-99999","1d6+hello"]:
        check(not Formula.parse(bad).get("ok",false),
            "Invalid formula was accepted: "+bad)
    check(not Formula.evaluate(Formula.parse("1d6"),[[7]]).get("ok",false),
        "Invented/invalid physical face D6=7 must be refused")
    check(not Formula.evaluate(Formula.parse("2d6"),[[5]]).get("ok",false),
        "Missing physical die result must be refused")
    check(not Formula.evaluate(Formula.parse("1d6"),[[3,4]],
        "advantage").get("ok",false),"Advantage cannot apply to D6")
    check(not Formula.evaluate(Formula.parse("2d20"),[[5,18,2]],
        "advantage").get("ok",false),"Advantage on a multi-D20 pool is ambiguous")
    check(not Formula.evaluate(Formula.parse("1d20"),[[[5,42]]]).get("ok",false),
        "Cannot accept an invalid reroll as physical D20")
    print("M4 pure real-face formula tests: %d checks, %d failures" %
        [checks,failed])
    quit(0 if failed==0 else 1)
