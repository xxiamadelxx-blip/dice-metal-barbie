"""Decode and measure ALL genuine Android AVD screen frames chronologically.

Results/HUD OCR not yet validated; this is temporal image evidence only.
The AVD's screenrecord input is sampled to nominal 24fps with ffmpeg; this
may drop or repeat source frames. Do NOT infer measured GPU FPS from that.
"""
import json
import math
import re
import sys
from pathlib import Path
from PIL import Image, ImageChops, ImageDraw, ImageStat
from audit_roll_sequence import video_frames, save_every_frame_sheet

def inspect(root, sides):
    key = str(sides)
    upper_bound = 100 if key == "100_PAIR" else int(sides)
    film = root / ("roll-D%s-24fps.mp4" % key)
    assert film.stat().st_size > 30000, "Missing Android AVD source for D%s" % sides
    godot_log=(root / ("roll-D%s-godot.log" % key)).read_text()
    assert "DICE_QA_STARTED D%s" % key in godot_log, "D%s no Godot start signal" % key
    matches=re.findall(r"DICE_QA_COMPLETED D%s=([0-9]+)" % key,godot_log)
    assert len(matches)==1, "D%s must have one Jolt result callback, got %d" % (key,len(matches))
    actual_result=int(matches[0])
    assert 1<=actual_result<=upper_bound, "D%s physically returned invalid %d" % (key,actual_result)
    assert "DICE_QA_FAILED D%s=" % key not in godot_log, "D%s Godot physical failure" % key
    assert (root / ("completed-D%s.png" % key)).stat().st_size>10000, "D%s no final ADB screenshot" % key
    old = None
    count = 0
    changes = 0
    duplicates = 0
    blackouts = 0
    strips = []
    every_second = []
    with (root / ("every-avd-frame-D%s.jsonl" % key)).open("w") as out:
        for idx,image in video_frames(film):
            a=image.crop((110,180,610,930)).resize((96,144)).convert("L")
            avg=ImageStat.Stat(a).mean[0]
            black=avg<8
            blackouts+=int(black)
            diff=0 if old is None else sum(ImageChops.difference(a,old).histogram()[10:])
            changes+=int(diff>36)
            duplicates+=int(diff==0 and old is not None)
            out.write(json.dumps({"frame":idx,"t_s":round(idx/24,4),"die_selected_by_android_tap":key,
                "luminance":round(avg,2),"black_screen":black,"changed_pixels_gt9":diff})+"\n")
            if idx%24==0:
                strips.append((idx,image.resize((160,284))))
            every_second.append((idx,image.resize((120,215))))
            if len(every_second)==24:
                save_every_frame_sheet(root,key,idx//24,every_second)
                every_second=[]
            old=a
            count+=1
    if every_second:
        save_every_frame_sheet(root,key,(count-1)//24,every_second)
    assert count>=100, "AVD screenrecord duration <4s for D%s" % sides
    assert blackouts==0, "D%s AVD has %d black frames" % (sides,blackouts)
    assert changes>=8, "D%s AVD has only %d moving frames; frozen throw" % (sides,changes)
    # Preserve all individual metrics, and sample 1-per-second keyframes only
    # for fast human inspection. No image is skipped by the per-frame critic.
    strips=strips[:18]
    sheet=Image.new("RGB",(160*6,314*math.ceil(len(strips)/6)),(16,18,24))
    pen=ImageDraw.Draw(sheet)
    for i,(frame,im) in enumerate(strips):
        x=(i%6)*160; y=(i//6)*314
        sheet.paste(im,(x,y+30))
        pen.text((x+4,y+6),"D%s t=%.1fs"%(sides,frame/24),fill=(237,225,190))
    sheet.save(root / ("contact-avd-D%s.jpg" % key),quality=87)
    return {"die":upper_bound,"capture_key":key,"real_godot_result":actual_result,
            "real_godot_start_and_completion":True,
            "full_24_frame_storyboards":math.ceil(count/24),
            "frames_checked_sequentially":count,
            "nominal_decoded_fps":24,"frames_with_pixel_changes":changes,
            "duplicate_frames":duplicates,"near_black_frames":blackouts,
            "hud_result_ocr":"NOT_VERIFIED","avd_physical_fps":"NOT_VERIFIED"}

def inspect_advanced_m4(root):
    """Additional ORIGINAL Android screenrecord of actual tapped advanced UI.
    This extends rather than weakens the existing eight baseline dice gates.
    """
    source=root/"dice-M4-source.mp4"
    film=root/"roll-M4-24fps.mp4"
    assert source.stat().st_size>30000, "Original M4 Android source recording missing"
    assert film.stat().st_size>30000, "M4 Android 24fps transcode missing"
    assert (root/"m4-drawer-open.png").stat().st_size>10000
    assert (root/"completed-M4.png").stat().st_size>10000
    assert (root/"m4-reroll-selector-open.png").stat().st_size>10000
    assert (root/"m4-after-reroll-tap.png").stat().st_size>10000
    log=(root/"roll-M4-godot.log").read_text()
    assert "DICE_M4_PHYSICAL_STARTED 2d6+1d20-3" in log, (
        "Actual Android M4 formula button never started Godot/Jolt")
    assert "DICE_M4_SIMULTANEOUS_STARTED=3" in log and (
        "DICE_M4_SIMULTANEOUS_COMPLETED=3" in log), (
        "Android must visibly launch and retain three actual Jolt source dice")
    matches=re.findall(r"DICE_M4_PHYSICAL_COMPLETED 2d6\+1d20-3=(-?[0-9]+)",log)
    assert len(matches)==2,"Android must physically complete original AND selected reroll"
    assert "DICE_M4_REAL_REROLL_STARTED group=0 die=0" in log, (
        "Real ADB click never selected the original physical D6 source")
    assert re.search(r"DICE_M4_REAL_REROLL_COMPLETED D6=[1-6] attempts=2",log), (
        "No real second D6 physical top face and preserved first attempt")
    assert "DICE_M4_PHYSICAL_FAILED" not in log,"Godot signaled a failed composite"
    actual=int(matches[0])
    rerolled=int(matches[1])
    assert 0<=actual<=29 and 0<=rerolled<=29, (
        "Original or rerolled physical formula result out of valid bounds")
    old=None
    frames=0
    motions=0
    duplicates=0
    black=0
    sheets=[]
    with (root/"every-avd-frame-M4.jsonl").open("w") as file:
        for frame,image in video_frames(film):
            # Include physical stage after drawer disappears; retain entire
            # original frame in chronological 24-per-second storyboards.
            crop=image.crop((80,150,640,930)).resize((96,144)).convert("L")
            luminance=ImageStat.Stat(crop).mean[0]
            diff=0 if old is None else sum(ImageChops.difference(crop,old).histogram()[10:])
            moving=old is not None and diff>36
            duplicate=old is not None and diff==0
            motions+=int(moving)
            duplicates+=int(duplicate)
            black+=int(luminance<8)
            file.write(json.dumps({"frame":frame,"t_s":round(frame/24,4),
                "source":"REAL_ANDROID_X86_64_JOLT_M4_ADVANCED_UI",
                "mean_luma":round(luminance,2),"changed_pixels":diff,
                "exact_duplicate":bool(duplicate),"black_frame":luminance<8})+"\n")
            sheets.append((frame,image.resize((120,215))))
            if len(sheets)==24:
                save_every_frame_sheet(root,"M4",frame//24,sheets)
                sheets=[]
            old=crop
            frames+=1
    if sheets:
        save_every_frame_sheet(root,"M4",(frames-1)//24,sheets)
    assert frames>=120,"M4 Android actual video shorter than 5 seconds"
    assert black==0,"M4 Android video has black game stage"
    assert motions>=8,"M4 Android UI and Jolt physical stage remain visually frozen"
    return {"capture_key":"M4_REAL_PHYSICAL_UI","real_formula":"2d6+1d20-3",
        "true_simultaneous_Jolt_bodies":3,"real_persisting_physical_bodies":3,
        "real_Jolt_result":actual,
        "rerolled_real_Jolt_result":rerolled,
        "real_player_Android_reroll_tapped":True,
        "real_D6_reroll_initial_face_preserved":True,
        "real_godot_start_and_completion":True,
        "frame_count_all_checked":frames,"ordered_24_frame_sheets":math.ceil(frames/24),
        "frames_with_visible_changes":motions,"duplicate_frames":duplicates,
        "black_frames":black,"hud_text_ocr":"NOT_VERIFIED",
        "recording_fps":24,"unique_render_fps":"NOT_VERIFIED"}

def main(root):
    all_dice=[inspect(root,s) for s in (4,6,8,12,20,10,100,"100_PAIR")]
    m4=inspect_advanced_m4(root)
    report={"provenance":"REAL_ANDROID_EMULATOR_X86_64_ADB_SCREENRECORD",
            "results":all_dice,"m4_real_clicked_physical_ui":m4,
            "frames_examined":sum(x["frames_checked_sequentially"] for x in all_dice)+m4["frame_count_all_checked"],
            "status":"TEMPORAL_EVIDENCE_ONLY",
            "limitations":["24fps extracted screen frames can repeat if AVD GPU/source is slower",
                           "actual FPS and numerical face/HUD consistency unverified",
                           "Android AVD is not a physical OnePlus Nord 3"]}
    (root/"android-avd-temporal-report.json").write_text(json.dumps(report,indent=2)+"\n")
    print(json.dumps(report))

if __name__=="__main__":
    main(Path(sys.argv[1] if len(sys.argv)>1 else "qa-evidence/android-avd"))
