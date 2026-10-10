"""Sequentially inspect every captured 24fps screenshot of each Jolt throw.

Frame N is decoded and compared with frame N-1; every frame gets a JSONL row.
No sparse sampling for defect detection. The JPEG sheets are only compact
human visual previews; every actual video frame is analyzed in this script.
This is Linux Mesa recording, NOT Android emulator/hardware footage.
"""
import json
import math
import subprocess
import sys
from pathlib import Path

from PIL import Image, ImageChops, ImageDraw, ImageStat

WIDTH, HEIGHT, FPS = 720, 1280, 24
BYTES_PER_FRAME = WIDTH * HEIGHT * 3
DICE = (4, 6, 8, 12, 20)


def video_frames(path):
    command = ["ffmpeg", "-v", "error", "-i", str(path), "-f", "rawvideo",
               "-pix_fmt", "rgb24", "-vsync", "0", "pipe:1"]
    proc = subprocess.Popen(command, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    try:
        index = 0
        while True:
            chunks = bytearray()
            while len(chunks) < BYTES_PER_FRAME:
                piece = proc.stdout.read(BYTES_PER_FRAME - len(chunks))
                if not piece:
                    break
                chunks.extend(piece)
            if not chunks:
                break
            if len(chunks) != BYTES_PER_FRAME:
                raise AssertionError("Truncated recorded screenshot %d of %s" % (index, path))
            yield index, Image.frombytes("RGB", (WIDTH, HEIGHT), bytes(chunks))
            index += 1
    finally:
        proc.stdout.close()
        error = proc.stderr.read().decode("utf-8", errors="replace")
        returncode = proc.wait(timeout=30)
        if returncode != 0:
            raise AssertionError("FFmpeg failed to decode all frames: " + error[-1200:])


def save_every_frame_sheet(root, sides, second, imgs):
    """All 24 actual chronological screenshots for exactly one video second."""
    sheet=Image.new("RGB",(6*120,4*235),(14,17,24))
    pen=ImageDraw.Draw(sheet)
    for position,(frame_id,thumb) in enumerate(imgs):
        x=position%6*120
        y=position//6*235
        sheet.paste(thumb,(x,y+20))
        pen.text((x+5,y+4),"F%04d %.2fs"%(frame_id,frame_id/24),
                 fill=(230,222,195))
    sheet.save(root/("ALL-24-frames-D%d-second-%02d.jpg"%(sides,second)),quality=88)

def inspect_throw(root, sides):
    timeline = json.loads((root / ("timeline-D%d.json" % sides)).read_text())
    assert timeline["die"] == sides and timeline["status"] == "completed"
    assert 1 <= timeline["result"] <= sides
    assert timeline["environment"] == "LINUX_MESA_NATIVE_NOT_ANDROID_EMULATOR"
    video = root / ("roll-D%d-24fps.mp4" % sides)
    assert video.stat().st_size > 25000, "Missing real footage of D%d" % sides
    result = {
        "die": sides, "physically_resolved_value": timeline["result"],
        "recording_target_fps": FPS,
        "godot_drawn_frames_before_result": timeline["godot_drawn_frames_to_result"],
        "seconds_to_physical_result": timeline["seconds_to_result"],
        "provenance": "REAL_LINUX_MESA_XVFB_JOLT_NOT_ANDROID_EMULATOR"
    }
    previous = None
    max_duplicate_run = 0
    duplicate_run = 0
    black_frames = 0
    black_during_capture = 0
    movement_frames = 0
    frames = 0
    brightness_range = [255.0, 0.0]
    anomalies = []
    preview = []
    full_second_frames = []
    t_to_go_approx = 0.8
    with (root / ("every-frame-D%d.jsonl" % sides)).open("w") as out:
        for index, image in video_frames(video):
            # Playfield: exclude static HUD and black screen-edge rails.
            sample = image.crop((110, 180, 610, 930)).resize((96, 144)).convert("L")
            stats = ImageStat.Stat(sample)
            luminance = stats.mean[0]
            brightness_range = [min(brightness_range[0], luminance),
                                max(brightness_range[1], luminance)]
            histogram = sample.histogram()
            black_share = sum(histogram[:10]) / float(96 * 144)
            if black_share > .97:
                black_frames += 1
                if index / FPS > t_to_go_approx + .2:
                    black_during_capture += 1
                    anomalies.append({"frame": index, "kind": "nearly_black_scene"})
            changed = 0
            if previous is not None:
                histogram_change = ImageChops.difference(sample, previous).histogram()
                changed = sum(histogram_change[10:])
                if changed == 0:
                    duplicate_run += 1
                else:
                    duplicate_run = 0
                if changed / float(96 * 144) > .0025:
                    movement_frames += 1
            max_duplicate_run = max(max_duplicate_run, duplicate_run)
            if index / FPS >= t_to_go_approx and index / FPS <= t_to_go_approx + timeline["seconds_to_result"]:
                if duplicate_run == 25:
                    anomalies.append({"frame": index, "kind": "one_second_identical_during_throw"})
            out.write(json.dumps({
                "frame": index,
                "timestamp_seconds": round(index / FPS, 4),
                "playfield_mean_luminance": round(luminance, 3),
                "nearly_black_fraction": round(black_share, 5),
                "changed_pixels_above_9": changed,
                "duplicate_run": duplicate_run,
                "real_die": sides
            }) + "\n")
            if index % 12 == 0:
                preview.append((index, image.resize((180, 320))))
            # Build exhaustive storyboard sheets. Unlike the quick-preview
            # contact, this retains every screen, ordered 24 per second.
            full_second_frames.append((index,image.resize((120,215))))
            if len(full_second_frames)==24:
                save_every_frame_sheet(root,sides,index//24,full_second_frames)
                full_second_frames=[]
            previous = sample
            frames += 1
    if full_second_frames:
        save_every_frame_sheet(root,sides,(frames-1)//24,full_second_frames)
    assert frames >= 48, "D%d missing 2+ seconds at 24fps" % sides
    assert movement_frames >= 8, "D%d moved in too few decoded frames" % sides
    assert black_frames < frames * .65, "D%d captured a mostly black renderer" % sides
    # Preserve a compact browsable index, full 24fps video remains uncut.
    preview = preview[:30]
    cols = 6
    strip = Image.new("RGB", (cols * 180, math.ceil(len(preview)/cols) * 346), (12, 15, 22))
    pen = ImageDraw.Draw(strip)
    for j, (frame_number, thumb) in enumerate(preview):
        x = (j % cols) * 180
        y = (j // cols) * 346
        strip.paste(thumb, (x, y + 26))
        pen.text((x + 5, y + 6), "D%d F%04d %.2fs" % (sides, frame_number, frame_number/FPS),
                 fill=(243, 235, 207))
    strip.save(root / ("contact-D%d.jpg" % sides), quality=88)
    result.update({
        "frames_read_in_order": frames,
        "duration_s": round(frames / FPS, 3),
        "frames_with_motion": movement_frames,
        "longest_identical_streak": max_duplicate_run,
        "nearly_black_frames": black_frames,
        "black_frames_after_physical_go": black_during_capture,
        "native_engine_render_fps_to_result": round(
            timeline["godot_drawn_frames_to_result"] / timeline["seconds_to_result"], 2),
        "engine_achieved_24_distinct_render_frames_per_second":
            (timeline["godot_drawn_frames_to_result"] / timeline["seconds_to_result"]) >= 23.5,
        "playfield_mean_luminance_range": [round(v, 2) for v in brightness_range],
        "anomalies": anomalies[:30],
        "anomaly_total": len(anomalies),
    })
    print(json.dumps(result))
    assert black_during_capture == 0, (
        "D%d has %d truly black video frames during the actual recording; "
        "see full video and every-frame JSONL" % (sides,black_during_capture))
    return result


def main(root):
    runs = [inspect_throw(root, sides) for sides in DICE]
    summary = {
        "status": "PASS_AUTOMATED_PER_FRAME_METRICS",
        "recording_frame_rate": FPS,
        "actual_engine_rate_note": "see each die's native_engine_render_fps_to_result field; do not treat video rate as engine FPS",
        "frames_examined_sequentially": sum(x["frames_read_in_order"] for x in runs),
        "dice": runs,
        "limitations": [
            "24fps recorded timeline is NOT proof of 24 unique rendered frames/second",
            "per-frame image/temporal metrics are NOT independent subjective visual review",
            "native Linux Mesa viewport, NOT Android emulator or OnePlus handset",
            "no frame interpolation used to fabricate motion"
        ]
    }
    (root / "temporal-report.json").write_text(json.dumps(summary, indent=2) + "\n")
    print("PASS: every decoded frame of five real physical dice was processed")
    print("Total frames:", summary["frames_examined_sequentially"])


if __name__ == "__main__":
    main(Path(sys.argv[1] if len(sys.argv) > 1 else "qa-evidence/temporal"))
