#!/usr/bin/env bash
# Genuine Godot/Mesa mobile viewport, full 24fps capture of M4 drawer click
# and physical mixed Jolt throw, not Android or interpolated frames.
set -euo pipefail
OUT=qa-evidence/m4-ui-24fps
mkdir -p "$OUT"
rm -f "$OUT"/ready "$OUT"/go "$OUT"/done "$OUT"/saved "$OUT"/summary.json
Xvfb :99 -screen 0 720x1280x24 -nolisten tcp > "$OUT/xvfb.log" 2>&1 &
xpid=$!
gpid=""
fpid=""
clean() {
  if [[ -n "$fpid" ]]; then kill -INT "$fpid" 2>/dev/null || true; wait "$fpid" 2>/dev/null || true; fi
  if [[ -n "$gpid" ]]; then kill "$gpid" 2>/dev/null || true; wait "$gpid" 2>/dev/null || true; fi
  kill "$xpid" 2>/dev/null || true
  wait "$xpid" 2>/dev/null || true
}
trap clean EXIT
export DISPLAY=:99
sleep 1
godot --path . --rendering-method gl_compatibility --script res://tests/m4_ui_temporal_capture.gd > "$OUT/godot-live.log" 2>&1 &
gpid=$!
for i in $(seq 1 450); do
  test -f "$OUT/ready" && break
  kill -0 "$gpid" 2>/dev/null || { tail -100 "$OUT/godot-live.log"; exit 1; }
  sleep .1
done
test -s "$OUT/ready"
ffmpeg -hide_banner -loglevel error -nostdin -y -f x11grab -framerate 24 \
  -video_size 720x1280 -i ':99.0+0,0' -c:v libx264 -preset ultrafast \
  -crf 20 -pix_fmt yuv420p -movflags +faststart "$OUT/m4-real-ui-24fps.mp4" \
  > "$OUT/ffmpeg.log" 2>&1 &
fpid=$!
sleep .8
kill -0 "$fpid"
touch "$OUT/go"
for i in $(seq 1 600); do
  test -f "$OUT/done" && break
  kill -0 "$gpid" 2>/dev/null || { tail -100 "$OUT/godot-live.log"; exit 1; }
  kill -0 "$fpid" 2>/dev/null || { cat "$OUT/ffmpeg.log"; exit 1; }
  sleep .1
done
test -s "$OUT/done"
sleep .3
kill -INT "$fpid" 2>/dev/null || true
wait "$fpid" || true
fpid=""
test -s "$OUT/m4-real-ui-24fps.mp4"
touch "$OUT/saved"
wait "$gpid"
gpid=""
grep -F 'PASS M4 UI actual real Jolt' "$OUT/godot-live.log"
echo 'PASS genuine M4 drawer and physical multi-dice screenshot timeline'
