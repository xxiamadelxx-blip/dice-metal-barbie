#!/usr/bin/env bash
# Real Android taps only; new source/MP4 and all screenshots retained even on FAIL.
set -euo pipefail
out=qa-evidence/android-avd
log="$out/roll-M4-PAIR-godot.log"
device=/sdcard/dice-M4-PAIR.mp4
source="$out/dice-M4-PAIR-source.mp4"
film="$out/roll-M4-PAIR-24fps.mp4"
mkdir -p "$out"
pid=""
finish() {
  local status=$?
  if test -n "$pid"; then
    running="$(adb shell pidof screenrecord | tr -d '\r' || true)"
    if test -n "$running"; then adb shell kill -2 $running || true; fi
    wait "$pid" || true
    pid=""
  fi
  adb logcat -d -v time -s godot:I '*:S' > "$log" || true
  adb exec-out screencap -p > "$out/m4-pair-final.png" || true
  adb pull "$device" "$source" || true
  adb shell rm "$device" || true
  if test -s "$source"; then
    ffmpeg -hide_banner -loglevel error -y -i "$source" -vf fps=24 \
      -c:v libx264 -preset ultrafast -crf 20 -pix_fmt yuv420p "$film" || true
  fi
  if test "$status" -ne 0 && test -s "$film"; then
    python3 tools/visual/snapshot_failed_avd_frames.py "$out" M4-PAIR || true
  fi
}
trap finish EXIT
adb shell am force-stop org.dicemetalbarbie.dnddice
adb shell monkey -p org.dicemetalbarbie.dnddice 1
sleep 8
adb exec-out screencap -p > "$out/m4-pair-before-drawer.png"
adb logcat -c || true
adb shell screenrecord --size 720x1280 --bit-rate 4500000 \
  --time-limit 175 "$device" &
pid=$!
sleep 1
adb shell input tap 50 97
sleep .8
adb exec-out screencap -p > "$out/m4-pair-formula-drawer.png"
# From genuine prior Android screenshot: formula input x32..688 y154..198.
adb shell input tap 250 175
adb shell input keyevent KEYCODE_MOVE_END
for i in $(seq 1 35); do adb shell input keyevent KEYCODE_DEL; done
adb shell input text '1d100+1d6'
adb shell input keyevent KEYCODE_BACK
sleep .8
adb exec-out screencap -p > "$out/m4-pair-formula-entered.png"
adb shell input tap 355 285
initial=0
for i in $(seq 1 55); do
  sleep 2
  adb logcat -d -v time -s godot:I '*:S' > "$log" || true
  if grep -Fq 'DICE_M4_PHYSICAL_FAILED ' "$log"; then break; fi
  if grep -Fq 'DICE_M4_PHYSICAL_STARTED 1d100+1d6' "$log" &&
     grep -Fq 'DICE_M4_SIMULTANEOUS_COMPLETED=3' "$log" &&
     grep -Eq 'DICE_M4_PHYSICAL_COMPLETED 1d100\+1d6=[0-9]+' "$log"; then
    initial=1; break
  fi
done
if test "$initial" != 1; then echo 'FAIL: player Android D100 pair formula'; exit 21; fi
adb exec-out screencap -p > "$out/m4-pair-physical-initial.png"
adb shell input tap 50 97
sleep .8
adb exec-out screencap -p > "$out/m4-pair-tens-picker.png"
adb shell input tap 624 340
tens=0
for i in $(seq 1 40); do
  sleep 2
  adb logcat -d -v time -s godot:I '*:S' > "$log" || true
  if grep -Fq 'DICE_M4_PHYSICAL_FAILED ' "$log"; then break; fi
  if grep -Fq 'DICE_M4_REAL_REROLL_STARTED group=0 die=0 digit=tens' "$log" &&
     grep -Eq 'DICE_M4_REAL_REROLL_COMPLETED D10=(10|[1-9]) attempts=2' "$log"; then
    tens=1; break
  fi
done
if test "$tens" != 1; then echo 'FAIL: Android did not reroll actual tens D10'; exit 22; fi
adb exec-out screencap -p > "$out/m4-pair-after-tens.png"
adb shell input tap 50 97
sleep .8
adb shell input tap 240 340
sleep .7
adb exec-out screencap -p > "$out/m4-pair-ones-popup.png"
# Verify the second item truly selected via required Jolt digit=ones event.
adb shell input tap 240 383
sleep .5
adb exec-out screencap -p > "$out/m4-pair-ones-selected.png"
adb shell input tap 624 340
ones=0
for i in $(seq 1 40); do
  sleep 2
  adb logcat -d -v time -s godot:I '*:S' > "$log" || true
  if grep -Fq 'DICE_M4_PHYSICAL_FAILED ' "$log"; then break; fi
  if grep -Fq 'DICE_M4_REAL_REROLL_STARTED group=0 die=0 digit=ones' "$log" &&
     grep -Eq 'DICE_M4_REAL_REROLL_COMPLETED D10=(10|[1-9]) attempts=3' "$log"; then
    ones=1; break
  fi
done
if test "$ones" != 1; then echo 'FAIL: Android did not reroll actual ones D10'; exit 23; fi
adb exec-out screencap -p > "$out/m4-pair-after-ones.png"
adb shell input tap 50 97
sleep .7
adb exec-out screencap -p > "$out/m4-pair-history-drawer.png"
adb shell input tap 540 482
sleep 1.1
adb exec-out screencap -p > "$out/m4-pair-full-history.png"
adb logcat -d -v time -s godot:I '*:S' > "$log" || true
if ! grep -Eq 'DICE_M4_HISTORY_OPEN records=([3-9]|[1-9][0-9]+)' "$log"; then
  echo 'FAIL: paired-D100 Android full history did not open'; exit 24
fi
finish
trap - EXIT
test -s "$film"
python3 - "$out/m4-pair-history-drawer.png" "$out/m4-pair-full-history.png" <<'PY'
import sys
from PIL import Image,ImageChops
a=Image.open(sys.argv[1]).convert("RGB")
b=Image.open(sys.argv[2]).convert("RGB")
assert a.size==b.size==(720,1280)
diff=ImageChops.difference(a.crop((30,60,690,1190)),
    b.crop((30,60,690,1190))).convert("L")
changed=sum(x for i,x in enumerate(diff.histogram()) if i>18)
print("Android D100 source history modal changed original pixels:",changed)
assert changed>15000
PY
echo 'PASS actual Android D100 tens and ones source taps'
