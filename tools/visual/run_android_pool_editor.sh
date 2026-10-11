#!/usr/bin/env bash
# New M4 pool-editor Android AVD player touch walkthrough, after 8 baseline
# real Jolt captures and actual selected D100 tens/ones. Not phone FPS proof.
set -euo pipefail
out=qa-evidence/android-avd
device=/sdcard/dice-M4-POOL.mp4
raw="$out/dice-M4-POOL-source.mp4"
film="$out/roll-M4-POOL-24fps.mp4"
log="$out/roll-M4-POOL-godot.log"
mkdir -p "$out"
recording=""
cleanup() {
  local status=$?
  if test -n "$recording"; then
    active="$(adb shell pidof screenrecord | tr -d '\r' || true)"
    if test -n "$active"; then adb shell kill -2 $active || true; fi
    wait "$recording" || true
    recording=""
  fi
  adb logcat -d -v time -s godot:I '*:S' > "$log" || true
  adb exec-out screencap -p > "$out/m4-pool-original-final.png" || true
  adb pull "$device" "$raw" || true
  adb shell rm "$device" || true
  if test -s "$raw"; then
    ffmpeg -hide_banner -loglevel error -y -i "$raw" -vf fps=24 \
      -c:v libx264 -preset ultrafast -crf 20 -pix_fmt yuv420p "$film" || true
  fi
  if test "$status" -ne 0 && test -s "$film"; then
    python3 tools/visual/snapshot_failed_avd_frames.py "$out" M4-POOL || true
  fi
}
trap cleanup EXIT
# Require a NEW Godot main scene. Reused Android buffer pixels from a prior
# history modal are not evidence of this app having launched correctly.
adb logcat -c || true
adb shell am force-stop org.dicemetalbarbie.dnddice
adb shell monkey -p org.dicemetalbarbie.dnddice 1
stage=0
for attempt in $(seq 1 20); do
  adb logcat -d -v time -s godot:I '*:S' > "$out/m4-pool-fresh-process.log" || true
  adb exec-out screencap -p > "$out/m4-pool-original-before-drawer.png"
  if grep -Fq 'DICE_QA_MAIN_SCENE_READY' "$out/m4-pool-fresh-process.log" &&
      python3 - "$out/m4-pool-original-before-drawer.png" <<'PY'
from PIL import Image,ImageStat
import sys
im=Image.open(sys.argv[1]).convert('RGB')
assert im.size==(720,1280)
m=ImageStat.Stat(im.crop((40,85,680,485)).convert('L'))
print('M4 original Android pool READY mean/std:',round(m.mean[0],2),round(m.stddev[0],2))
assert 7<m.mean[0]<150 and m.stddev[0]>6,'Not the playable original Godot stage'
PY
  then stage=1; break; fi
  cp "$out/m4-pool-original-before-drawer.png" "$out/m4-pool-not-ready-$attempt.png"
  sleep 5
done
if test "$stage" != 1; then echo 'FAIL: no fresh playable Android dice table for pool'; exit 51; fi
adb logcat -c || true
adb shell screenrecord --size 720x1280 --bit-rate 4500000 --time-limit 75 "$device" &
recording=$!
sleep 1
# One ACTUAL Android player tap to the previously accepted hamburger.
adb shell input tap 50 97
drawer=0
for attempt in $(seq 1 15); do
  sleep .8
  adb exec-out screencap -p > "$out/m4-pool-original-drawer.png"
  if python3 - "$out/m4-pool-original-before-drawer.png" "$out/m4-pool-original-drawer.png" <<'PY'
from PIL import Image,ImageChops
import sys
a=Image.open(sys.argv[1]).convert('RGB')
b=Image.open(sys.argv[2]).convert('RGB')
assert a.size==b.size==(720,1280)
d=ImageChops.difference(a.crop((17,110,703,580)),b.crop((17,110,703,580))).convert('L')
different=sum(n for v,n in enumerate(d.histogram()) if v>16)
print('M4 pool real Android drawer pixels:',different)
assert different>8500,'Wait for truly displayed advanced drawer'
PY
  then drawer=1; break; fi
  cp "$out/m4-pool-original-drawer.png" "$out/m4-pool-drawer-wait-$attempt.png"
done
if test "$drawer" != 1; then echo 'FAIL: actual editor parent drawer not visible'; exit 52; fi
# The new 84x46 "НАБОР" button is in the original formula input's x604..688
# right end at y~175, without moving the previously accepted throw controls.
adb shell input tap 632 175
popup=0
for attempt in $(seq 1 20); do
  sleep .8
  adb exec-out screencap -p > "$out/m4-pool-original-dialog.png"
  adb logcat -d -v time -s godot:I '*:S' > "$log" || true
  if grep -Fq 'DICE_M4_POOL_EDITOR_OPEN formula=2d6+1d20-3' "$log" &&
     python3 - "$out/m4-pool-original-drawer.png" "$out/m4-pool-original-dialog.png" <<'PY'
from PIL import Image,ImageChops
import sys
a=Image.open(sys.argv[1]).convert('RGB')
b=Image.open(sys.argv[2]).convert('RGB')
assert a.size==b.size==(720,1280)
d=ImageChops.difference(a.crop((40,190,680,1140)),b.crop((40,190,680,1140))).convert('L')
different=sum(n for v,n in enumerate(d.histogram()) if v>18)
print('M4 pool ACTUAL dialog visible changed original pixels:',different)
assert different>15000,'Godot window telemetry alone not sufficient: dialog pixels missing'
PY
  then popup=1; break; fi
  cp "$out/m4-pool-original-dialog.png" "$out/m4-pool-dialog-wait-$attempt.png"
done
if test "$popup" != 1; then echo 'FAIL: player physical pool editor popup never rendered'; exit 53; fi
# Keep at least 5 seconds of full source frames after the popup appears.
sleep 5
adb logcat -d -v time -s godot:I '*:S' > "$log" || true
# Merely opening and inspecting a draft MUST NOT physically throw or
# replace any stored original Jolt face, result or existing history.
if grep -Eq 'DICE_M4_POOL_APPLIED|DICE_M4_PHYSICAL_STARTED' "$log"; then
  echo 'FAIL: opening the editor implicitly applied a draft or started Jolt'
  exit 54
fi
cleanup
trap - EXIT
test -s "$film"
echo 'PASS original Android visible editable-pool dialog and unchanged physics'
