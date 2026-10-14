extends SceneTree
const M5Art=preload("res://src/dice/m5_original_obsidian_art.gd")
const Pool=preload("res://src/core/physical_roll_pool.gd")
var checks:=0
var failures:=0
func _initialize()->void:
    call_deferred("_run")
func expect(ok:bool,msg:String)->void:
    checks+=1
    if not ok:
        failures+=1
        push_error("M5_MIXED_JOLT_FAIL "+msg)
func _await_pool(pool: Node3D, limit:int=2900)->bool:
    for t in range(limit):
        if not pool.busy:
            return true
        await physics_frame
    return false
func _run()->void:
    ProjectSettings.set_setting(M5Art.PROJECT_FLAG,true)
    var scene:=load("res://src/main.tscn").instantiate() as Node3D
    root.add_child(scene)
    await process_frame
    var pool:=Pool.new()
    pool.name="M5GenuinePrivateMixedRoll"
    scene.add_child(pool)
    for trial in range(2):
        expect(pool.begin("1d20+2d6"),"pool.begin failed trial "+str(trial))
        var finished:=await _await_pool(pool)
        expect(finished,"pool did not complete trial "+str(trial))
        var receipt:Dictionary=pool.last_result
        expect(bool(receipt.get("ok",false)),"pool returned physical failure "+str(pool.last_physical_error))
        if not bool(receipt.get("ok",false)):
            break
        var active:Array=pool._active
        expect(active.size()==3,"1d20+2d6 must have 3 physical bodies")
        var premium_count:=0
        var printed_value:=-1
        for i in range(active.size()):
            var die:RigidBody3D=active[i]
            var sides:int=int(pool._last_plan[i]["sides"])
            var actual:int=int(pool.call("_actual_top",die,sides))
            expect(actual==int(die.get("result")),"mixed roll body value differs from true top")
            if sides==20:
                premium_count+=1
                expect(bool(die.get("m5_original_visual_active")),"premium D20 visual did not activate in pool")
                expect(actual==int(die.call("top_visible_value")),"D20 chosen label differs from physical gold top")
                printed_value=actual
        expect(premium_count==1,"expected exactly one licensed 500k D20")
        print("M5_MIXED_JOLT_REAL_RESULT trial=",trial," native_d20=",printed_value," sum=",receipt.get("total")," dice=",active.size())
        if trial==0:
            # Real one-body D20 reroll: keep two settled D6 physically in place.
            var previous_d6:Dictionary={}
            for i in range(active.size()):
                if int(pool._last_plan[i]["sides"])==6:
                    previous_d6[active[i].get_instance_id()]=int(active[i].get("result"))
            var reroll_started:bool=pool.reroll_one(0,0,"")
            expect(reroll_started,"physical D20 source reroll did not start")
            var settled:=await _await_pool(pool)
            expect(settled,"D20 physical reroll did not complete")
            expect(bool(pool.last_result.get("ok",false)),"D20 physical reroll receipt missing")
            for i in range(pool._active.size()):
                var die:RigidBody3D=pool._active[i]
                if int(pool._last_plan[i]["sides"])==6:
                    expect(int(die.get("result"))==int(previous_d6.get(die.get_instance_id(),-1)),"kept D6 changed during D20 reroll")
                if int(pool._last_plan[i]["sides"])==20:
                    expect(int(die.get("result"))==int(die.call("top_visible_value")),"rerolled D20 no longer matches engraved gold")
            print("M5_MIXED_JOLT_D20_PHYSICAL_REROLL accepted=",pool.last_result.get("ok")," result_total=",pool.last_result.get("total"))
    print("M5_MIXED_POOL_PRIVATE_NATIVE_JOLT_RESULT checks=",checks," failures=",failures)
    quit(0 if failures==0 else 33)