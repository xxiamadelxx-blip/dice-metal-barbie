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

def main(root):
    all_dice=[inspect(root,s) for s in (4,6,8,12,20,10,100,"100_PAIR")]
    report={"provenance":"REAL_ANDROID_EMULATOR_X86_64_ADB_SCREENRECORD",
            "results":all_dice,
            "frames_examined":sum(x["frames_checked_sequentially"] for x in all_dice),
            "status":"TEMPORAL_EVIDENCE_ONLY",
            "limitations":["24fps extracted screen frames can repeat if AVD GPU/source is slower",
                           "actual FPS and numerical face/HUD consistency unverified",
                           "Android AVD is not a physical OnePlus Nord 3"]}
    (root/"android-avd-temporal-report.json").write_text(json.dumps(report,indent=2)+"\n")
    print(json.dumps(report))

if __name__=="__main__":
    main(Path(sys.argv[1] if len(sys.argv)>1 else "qa-evidence/android-avd"))
