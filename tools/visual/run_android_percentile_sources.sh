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
# Clear the PREVIOUS session's Godot events BEFORE relaunch. A screenshot can
# retain the old history popup after force-stop, so pixels alone are NOT proof.
adb logcat -c || true
adb shell am force-stop org.dicemetalbarbie.dnddice
adb shell monkey -p org.dicemetalbarbie.dnddice 1
# Wait for THIS new debug Godot main scene to finish creating its real HUD.
# Every failed original frame and log remains available for independent QA.
ready=0
for attempt in $(seq 1 20); do
  adb logcat -d -v time -s godot:I '*:S' > "$out/m4-pair-restart-godot.log" || true
  # Only a fresh scene-ready marker emitted AFTER logcat -c qualifies.
  if ! grep -Fq 'DICE_QA_MAIN_SCENE_READY' "$out/m4-pair-restart-godot.log"; then
    adb exec-out screencap -p > "$out/m4-pair-before-drawer.png"
    cp "$out/m4-pair-before-drawer.png" "$out/m4-pair-not-ready-$attempt.png"
    sleep 5
    continue
  fi
  adb exec-out screencap -p > "$out/m4-pair-before-drawer.png"
  if python3 - "$out/m4-pair-before-drawer.png" <<'PY'
import sys
from PIL import Image, ImageStat
im = Image.open(sys.argv[1]).convert('RGB')
assert im.size == (720, 1280), f'Unexpected Android viewport {im.size}'
s = ImageStat.Stat(im.crop((40, 85, 680, 485)).convert('L'))
print('M4 pair AVD restart stage:', round(s.mean[0], 2), round(s.stddev[0], 2))
assert 7 < s.mean[0] < 150 and s.stddev[0] > 6, 'Android game not playable yet'
PY
  then
    ready=1
    break
  fi
  cp "$out/m4-pair-before-drawer.png" "$out/m4-pair-not-ready-$attempt.png"
  sleep 5
done
if test "$ready" != 1; then
  adb logcat -d -v time > "$out/m4-pair-restart-not-ready.log" || true
  echo 'FAIL: NEW Android Godot process or playable stage was not verified'
  exit 20
fi
adb logcat -c || true
adb shell screenrecord --size 720x1280 --bit-rate 4500000 \
  --time-limit 175 "$device" &
pid=$!
sleep 1
# Real 38151700973 AVD proved Android/Godot input-to-render latency:
# the first screenshot after this exact tap remained byte-for-byte unchanged,
# while trap's final original screenshot already contained the REAL open drawer.
# Send ONE tap, wait for a visibly new rendered HUD. Never double-tap a still
# loading screen (which could toggle the correctly opened drawer closed).
adb shell input tap 50 97
drawer_open=0
for attempt in $(seq 1 15); do
  sleep .8
  adb exec-out screencap -p > "$out/m4-pair-formula-drawer.png"
  if python3 - "$out/m4-pair-before-drawer.png" "$out/m4-pair-formula-drawer.png" <<'PY'
import sys
from PIL import Image, ImageChops
before=Image.open(sys.argv[1]).convert('RGB')
after=Image.open(sys.argv[2]).convert('RGB')
assert before.size==after.size==(720,1280), 'D100 pair drawer viewport mismatch'
d=ImageChops.difference(before.crop((17,110,703,580)),
                        after.crop((17,110,703,580))).convert('L')
changed=sum(n for v,n in enumerate(d.histogram()) if v>16)
print('M4 Android pair ACTUAL drawer changed pixels:',changed)
assert changed>8500, 'Awaiting actually rendered advanced drawer'
PY
  then
    drawer_open=1
    break
  fi
  cp "$out/m4-pair-formula-drawer.png" "$out/m4-pair-drawer-pending-$attempt.png"
done
if test "$drawer_open" != 1; then
  echo 'FAIL: real Godot advanced drawer did not become visually available after one Android tap'
  exit 28
fi
# From genuine prior Android screenshot: formula input x32..688 y154..198.
adb shell input tap 250 175
adb shell input keyevent KEYCODE_MOVE_END
for i in $(seq 1 35); do adb shell input keyevent KEYCODE_DEL; done
adb shell input text '1d100+1d6'
# DO NOT send KEYCODE_BACK: on the real Android AVD the keyboard is already
# absent and BACK takes the actual Godot app to Pixel Launcher. The source
# 38149288426 screenshot showed the correct formula AND the full drawer just
# before the old BACK; the final screenshot was the Android home screen.
sleep .8
adb exec-out screencap -p > "$out/m4-pair-formula-entered.png"
# Original Android screen must STILL show the active app/drawer. Stale, blank,
# launcher or accidental full-screen navigation cannot qualify as success.
python3 - "$out/m4-pair-before-drawer.png" "$out/m4-pair-formula-entered.png" <<'PY'
import sys
from PIL import Image, ImageChops
before=Image.open(sys.argv[1]).convert('RGB')
after=Image.open(sys.argv[2]).convert('RGB')
assert before.size==after.size==(720,1280)
d=ImageChops.difference(before.crop((17,110,703,580)),after.crop((17,110,703,580))).convert('L')
changed=sum(n for v,n in enumerate(d.histogram()) if v>16)
print('M4 pair Android actual editor still visible:',changed,'different pixels')
assert changed>8500,'Real formula drawer vanished before launch; do not tap Launcher'
PY
app_pid="$(adb shell pidof org.dicemetalbarbie.dnddice | tr -d '\r' || true)"
if test -z "$app_pid"; then
  echo 'FAIL: Godot Android process quit after original text input'
  exit 25
fi
adb shell input tap 355 285
sleep .5
adb exec-out screencap -p > "$out/m4-pair-after-formula-tap.png"
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
# Grounded ORIGINAL AVD screenshot #38150379151: the dropdown opens as
# a grey x45..550, y365..450 panel. The second item ("единицы") is centered
# near x240,y405. The old y383 tap selected the FIRST "десятки" again!
# Never send source reroll until the actual popup pixels AND selected Godot
# signal prove this is the original SECOND real D10, not the first.
adb shell input tap 535 340
popup_ready=0
for attempt in $(seq 1 10); do
  sleep .7
  adb exec-out screencap -p > "$out/m4-pair-ones-popup.png"
  if python3 - "$out/m4-pair-ones-popup.png" <<'PY'
import sys
from PIL import Image,ImageStat
im=Image.open(sys.argv[1]).convert('RGB')
assert im.size==(720,1280)
stat=ImageStat.Stat(im.crop((45,365,550,447)).convert('L'))
print('Original Android paired-source picker popup mean/stddev:',
      round(stat.mean[0],2),round(stat.stddev[0],2))
assert stat.mean[0]>50 and stat.stddev[0]>20, 'Original grey Android picker not shown'
PY
  then
    popup_ready=1
    break
  fi
done
if test "$popup_ready" != 1; then
  echo 'FAIL: paired D100 source dropdown never became visible'
  exit 26
fi
adb shell input tap 240 405
sleep .7
adb exec-out screencap -p > "$out/m4-pair-ones-selected.png"
adb logcat -d -v time -s godot:I '*:S' > "$log" || true
if ! grep -Fq 'DICE_M4_SOURCE_SELECTED group=0 die=0 digit=ones' "$log"; then
  echo 'FAIL: real Android picker did NOT select physical ones D10'
  exit 27
fi
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
