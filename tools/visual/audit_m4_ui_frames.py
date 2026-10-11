#!/usr/bin/env python3
"""Every real M4 mobile UI screenshot at nominal 24fps, frame by frame.
Never substitutes synthetic images or mistakes 24fps video for GPU 24fps.
"""
import json
import math
import subprocess
import sys
from pathlib import Path

from PIL import Image, ImageDraw, ImageChops, ImageStat

WIDTH,HEIGHT,FPS=720,1280,24
FRAME_BYTES=WIDTH*HEIGHT*3

def read_frames(path):
    proc=subprocess.Popen(["ffmpeg","-v","error","-i",str(path),
        "-f","rawvideo","-pix_fmt","rgb24","-vsync","0","pipe:1"],
        stdout=subprocess.PIPE,stderr=subprocess.PIPE)
    try:
        number=0
        while True:
            raw=bytearray()
            while len(raw)<FRAME_BYTES:
                chunk=proc.stdout.read(FRAME_BYTES-len(raw))
                if not chunk:
                    break
                raw.extend(chunk)
            if not raw:
                break
            if len(raw)!=FRAME_BYTES:
                raise AssertionError(f"Truncated decoded M4 frame {number}")
            yield number,Image.frombytes("RGB",(WIDTH,HEIGHT),bytes(raw))
            number+=1
    finally:
        proc.stdout.close()
        err=proc.stderr.read().decode(errors="replace")
        code=proc.wait(timeout=40)
        if code:
            raise AssertionError("FFmpeg decode error: "+err[-800:])

def sheet(out,second,ordered):
    img=Image.new("RGB",(720,4*235),(12,17,24))
    pen=ImageDraw.Draw(img)
    for i,(number,thumbnail) in enumerate(ordered):
        x=i%6*120
        y=i//6*235
        img.paste(thumbnail,(x,y+20))
        pen.text((x+5,y+3),f"F{number:04d} {number/FPS:.2f}s",fill=(235,223,195))
    img.save(out/f"M4-ALL-24-FRAMES-second-{second:02d}.jpg",quality=87)

def run(path):
    out=Path(path)
    data=json.loads((out/"summary.json").read_text())
    assert data["status"]=="completed" and data["real_physical_groups"]>=2
    assert data["real_visible_retained_Jolt_bodies"]>=2, "Source movie lost an original Jolt die"
    assert data["peak_simultaneously_rolling"]>=2, "Jolt throws were sequential, not concurrent"
    assert (out/"done").exists()
    film=out/"m4-real-ui-24fps.mp4"
    assert film.stat().st_size>30000
    total=0
    moves=0
    black=0
    repeats=0
    max_streak=0
    frames_in_second=[]
    prev=None
    all_24_sheets=0
    with (out/"every-m4-ui-frame.jsonl").open("w") as trace:
        for number,img in read_frames(film):
            cropped=img.crop((110,180,610,930)).resize((100,150)).convert("L")
            luminance=ImageStat.Stat(cropped).mean[0]
            hist=cropped.histogram()
            blank_share=sum(hist[:10])/15000.0
            changed=0 if prev is None else sum(ImageChops.difference(cropped,prev).histogram()[11:])
            if prev is not None and changed==0:
                repeats+=1
                max_streak+=1
            else:
                max_streak=0
            if changed>30:
                moves+=1
            if blank_share>.98:
                black+=1
            trace.write(json.dumps({"frame":number,"t_seconds":round(number/FPS,4),
                "mean_luma":round(luminance,2),"nearly_black_fraction":round(blank_share,4),
                "changed_pixels":changed,"identical_streak":max_streak})+"\n")
            frames_in_second.append((number,img.resize((120,215))))
            if len(frames_in_second)==FPS:
                sheet(out,number//FPS,frames_in_second)
                all_24_sheets+=1
                frames_in_second=[]
            total+=1
            prev=cropped
    if frames_in_second:
        sheet(out,total//FPS,frames_in_second)
        all_24_sheets+=1
    assert total>=100,f"Only {total} M4 screenshot frames"
    assert moves>15,f"Only {moves} changed M4 frames"
    assert black==0,f"{black} black M4 stage frames"
    assert all_24_sheets==math.ceil(total/FPS)
    report={"status":"PASS_REAL_PIXELS_AUTOMATED_ONLY",
        "environment":"REAL_GODOT_LINUX_MESA_NOT_ANDROID_HARDWARE",
        "source_video":film.name,"target_capture_fps":FPS,
        "decoded_frames_every_one_audited":total,
        "consecutive_contact_sheets":all_24_sheets,
        "nearly_black_frames":black,"frames_with_pixel_motion":moves,
        "identical_decoded_frames":repeats,
        "physical_formula":data["physical_formula"],
        "actual_physical_value":data["real_Jolt_result"],
        "original_retained_visible_jolt_bodies":data["real_visible_retained_Jolt_bodies"],
        "peak_truly_simultaneously_rolling_bodies":data["peak_simultaneously_rolling"],
        "engine_render_fps_during_physics":
            round(data["frames_drawn_during_real_physics"]/data["seconds_real_body_rolls"],2),
        "limitations":[
            "24fps video does not imply 24 unique rendered frames per second",
            "Automated pixels do not mean independent semantic visual approval",
            "Linux Mesa screen, not Android AVD or OnePlus Nord 3"]}
    (out/"m4-ui-frame-audit.json").write_text(json.dumps(report,indent=2)+"\n")
    print(json.dumps(report,indent=2))

if __name__=="__main__":
    run(sys.argv[1])
