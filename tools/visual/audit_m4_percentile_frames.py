#!/usr/bin/env python3
"""Adversarial every-original-pixel audit: genuine two-body D100 reroll UI.
Never substitutes generated images or claims GPU 24 unique FPS.
"""
import json, math, re, sys
from pathlib import Path
from PIL import ImageChops, ImageStat
from audit_m4_ui_frames import read_frames, sheet, FPS

def check(root):
    out=Path(root)
    summary=json.loads((out/"summary.json").read_text())
    assert summary.get("status")=="completed"
    assert summary.get("two_Jolt_sources_physically_rerolled") is True
    assert summary.get("original_and_repeated_outcomes_stored") is True
    assert summary.get("real_physical_sources")==3
    pairs=summary.get("original_and_new_real_D10_pairs")
    assert isinstance(pairs,list) and len(pairs)==2,"Both ACTUAL pairs not archived"
    for pair in pairs:
        assert len(pair)==2 and all(type(v) is int and 1<=v<=10 for v in pair)
    def value(pair):
        return ((pair[0]%10)*10+(pair[1]%10)) or 100
    assert value(pairs[0])==summary["original_D100"]
    assert value(pairs[1])==summary["rerolled_D100"]
    assert value(pairs[1])+summary["untouched_D4"]-2==summary["final_sum"]
    logs=(out/"godot-live.log").read_text()
    assert "DICE_M4_REAL_PERCENTILE_REROLL_COMPLETED" in logs
    matches=re.findall(r"DICE_M4_REAL_PERCENTILE_REROLL_COMPLETED D100=(\d+) attempts=(\d+)",logs)
    assert len(matches)==1 and int(matches[0][0])==value(pairs[1]) and int(matches[0][1])==2
    video=out/"m4-real-ui-24fps.mp4"
    assert video.stat().st_size>30000
    total=black=changed=repeat=0
    prev=None
    page=[]
    pages=0
    with (out/"every-real-percentile-reroll-frame.jsonl").open("w") as evidence:
        for idx,frame in read_frames(video):
            crop=frame.crop((110,180,610,930)).resize((100,150)).convert("L")
            lum=ImageStat.Stat(crop).mean[0]
            histogram=crop.histogram()
            fraction_black=sum(histogram[:10])/15000.0
            motion=0 if prev is None else sum(ImageChops.difference(crop,prev).histogram()[11:])
            if prev is not None and motion==0:
                repeat+=1
            if motion>30:
                changed+=1
            if fraction_black>.98:
                black+=1
            evidence.write(json.dumps({"frame":idx,"time_s":round(idx/FPS,4),
                "actual_source":"Godot Mesa 720x1280 source screen recording",
                "black_fraction":round(fraction_black,5),"mean_luma":round(lum,3),
                "changed_pixel_count":motion})+"\n")
            page.append((idx,frame.resize((120,215))))
            if len(page)==FPS:
                sheet(out,idx//FPS,page)
                pages+=1
                page=[]
            prev=crop
            total+=1
    if page:
        sheet(out,total//FPS,page)
        pages+=1
    assert total>=120,"Actual physical movie shorter than five seconds"
    assert pages==math.ceil(total/FPS)
    assert changed>=15,"Physical pair or UI looks frozen"
    assert black==0,"Black game frames present"
    report={"status":"PASS_REAL_FRAMES_NOT_PHONE",
        "frames_original_decoded":total,"24_consecutive_frames_per_contact_sheet":FPS,
        "full_second_sheets":pages,"frames_with_real_pixel_motion":changed,
        "blank_frames":black,"repeated_decoded_frames":repeat,
        "physical_source_faces_before_and_after":pairs,
        "real_selected_D100_pair_reroll":True,
        "drawn_frames_during_recorded_physics":summary["drawn_frames"],
        "capture_cadence_fps":FPS,
        "actual_unique_gpu_fps":"NOT_VERIFIED",
        "real_OnePlus_Nord3_fps":"NOT_VERIFIED",
        "environment":"native Godot 4.6.3 Mesa, NOT Android"}
    (out/"independent-percentile-frame-audit.json").write_text(
        json.dumps(report,ensure_ascii=False,indent=2)+"\n")
    print(json.dumps(report,ensure_ascii=False,indent=2))
if __name__=="__main__":
    check(sys.argv[1])
