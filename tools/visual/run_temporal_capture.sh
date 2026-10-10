#!/usr/bin/env bash
# Live 720x1280 Godot/Mesa/Jolt window captured by FFmpeg at target 24fps.
# This is NOT an Android emulator. Five real die throws, five videos.
set -euo pipefail
mkdir -p qa-evidence/temporal
rm -f qa-evidence/temporal/ready-D* qa-evidence/temporal/go-D* qa-evidence/temporal/done-D* qa-evidence/temporal/saved-D* qa-evidence/temporal/timeline-D*
Xvfb :99 -screen 0 720x1280x24 -nolisten tcp > qa-evidence/temporal/xvfb.log 2>&1 &
xvfb_pid=$!
godot_pid=""
rec_pid=""
cleanup() {
  if [[ -n "$rec_pid" ]]; then kill -INT "$rec_pid" 2>/dev/null || true; wait "$rec_pid" 2>/dev/null || true; fi
  if [[ -n "$godot_pid" ]]; then kill "$godot_pid" 2>/dev/null || true; wait "$godot_pid" 2>/dev/null || true; fi
  kill "$xvfb_pid" 2>/dev/null || true
  wait "$xvfb_pid" 2>/dev/null || true
}
trap cleanup EXIT
export DISPLAY=:99
sleep 1
godot --path . --rendering-method gl_compatibility --script res://tests/temporal_roll_capture.gd > qa-evidence/temporal/godot-live.log 2>&1 &
godot_pid=$!
for sides in 4 6 8 12 20; do
  echo "Waiting for REAL Jolt D$sides scene..."
  attempts=0
  until test -f "qa-evidence/temporal/ready-D$sides"; do
    if ! kill -0 "$godot_pid" 2>/dev/null; then
      tail -100 qa-evidence/temporal/godot-live.log >&2
      echo "FAIL: Godot died before D$sides" >&2
      exit 1
    fi
    attempts=$((attempts+1))
    if (( attempts > 600 )); then echo "FAIL: D$sides READY timed out" >&2; exit 1; fi
    sleep .1
  done
  ffmpeg -hide_banner -loglevel error -nostdin -y -f x11grab -framerate 24 \
    -video_size 720x1280 -i ':99.0+0,0' \
    -c:v libx264 -preset ultrafast -crf 19 -pix_fmt yuv420p \
    -movflags +faststart "qa-evidence/temporal/roll-D$sides-24fps.mp4" \
    > "qa-evidence/temporal/ffmpeg-D$sides.log" 2>&1 &
  rec_pid=$!
  sleep .8
  if ! kill -0 "$rec_pid" 2>/dev/null; then
    cat "qa-evidence/temporal/ffmpeg-D$sides.log" >&2
    echo "FAIL: screen recording could not start" >&2
    exit 1
  fi
  touch "qa-evidence/temporal/go-D$sides"
  attempts=0
  until test -f "qa-evidence/temporal/done-D$sides"; do
    if ! kill -0 "$godot_pid" 2>/dev/null; then
      tail -100 qa-evidence/temporal/godot-live.log >&2
      echo "FAIL: real throw aborted" >&2
      exit 1
    fi
    if ! kill -0 "$rec_pid" 2>/dev/null; then
      cat "qa-evidence/temporal/ffmpeg-D$sides.log" >&2
      echo "FAIL: FFmpeg recorder unexpectedly stopped" >&2
      exit 1
    fi
    attempts=$((attempts+1))
    if (( attempts > 165 )); then echo "FAIL: D$sides roll recording timed out" >&2; exit 1; fi
    sleep .1
  done
  sleep .2
  kill -INT "$rec_pid" 2>/dev/null || true
  wait "$rec_pid" || true
  rec_pid=""
  test -s "qa-evidence/temporal/roll-D$sides-24fps.mp4"
  # Let Godot move to the next throw (or quit) ONLY after FFmpeg flush.
  touch "qa-evidence/temporal/saved-D$sides"
  echo "Completed sequential recording for D$sides"
done
wait "$godot_pid"
godot_pid=""
grep -F "PASS all five real physical throws finished" qa-evidence/temporal/godot-live.log
echo "PASS 5 screen recordings at target 24fps"
