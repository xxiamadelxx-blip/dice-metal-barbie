"""Preserve *every* source screenshot of an AVD throw that never completed.

This analysis runs EVEN IF the real Jolt event is missing. It never converts
failure to success, never fabricates physical outcomes, never skips video
frames. Intended to debug slow software-emulator timing and visual freezes.
"""
import json
import sys
from pathlib import Path
from PIL import ImageChops, ImageStat
from audit_roll_sequence import video_frames, save_every_frame_sheet

def capture(root: Path, key: str) -> int:
    movie = root / ("roll-D%s-24fps.mp4" % key)
    if key == "M4" and not movie.is_file():
        movie = root / "roll-M4-24fps.mp4"
    if not movie.is_file():
        raise FileNotFoundError(movie)
    previous = None
    second = []
    frames = 0
    changed = 0
    duplicates = 0
    black = 0
    with (root / ("failed-every-avd-frame-D%s.jsonl" % key)).open("w") as out:
        for i,image in video_frames(movie):
            crop = image.crop((110,180,610,930)).resize((96,144)).convert("L")
            luminosity = ImageStat.Stat(crop).mean[0]
            diff = (sum(ImageChops.difference(crop,previous).histogram()[10:])
                    if previous is not None else 0)
            changed += int(diff > 36)
            duplicates += int(diff == 0 and previous is not None)
            black += int(luminosity < 8)
            out.write(json.dumps({"index":i,"time_s":round(i/24,4),
                "luminance":round(luminosity,2),"changed_pixels":diff,
                "nearly_black":luminosity < 8})+"\n")
            second.append((i,image.resize((120,215))))
            if len(second)==24:
                save_every_frame_sheet(root,"FAILED_"+key,i//24,second)
                second=[]
            previous=crop
            frames+=1
    if second:
        save_every_frame_sheet(root,"FAILED_"+key,(frames-1)//24,second)
    report={"capture_key":key,"physical_completion":"NOT_SEEN_FAIL",
        "frames_decoded":frames,"changed_frames":changed,
        "identical_frames":duplicates,"black_frames":black,
        "nominal_capture_fps":24,
        "claim":"Diagnostic only: no valid real Jolt result was observed"}
    (root / ("failed-avd-D%s-report.json" % key)).write_text(
        json.dumps(report,indent=2)+"\n")
    print(json.dumps(report))
    return frames

if __name__=="__main__":
    capture(Path(sys.argv[1]),sys.argv[2])
