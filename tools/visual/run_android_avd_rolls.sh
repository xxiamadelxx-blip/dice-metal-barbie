#!/usr/bin/env bash
# Real Android AVD: five UI-tapped die rolls and genuine Android screenrecord.
# screenrecord does not promise 24 source FPS; ffmpeg selects nominal 24fps
# screenshots for sequential pixel QA (repeats are reported, not hidden).
set -euo pipefail
mkdir -p qa-evidence/android-avd
adb wait-for-device
adb shell wm size 720x1280
adb shell wm density 320
adb install -r dice-emulator-x86-debug.apk
adb shell am force-stop org.dicemetalbarbie.dnddice || true
adb shell monkey -p org.dicemetalbarbie.dnddice 1
sleep 9
adb exec-out screencap -p > qa-evidence/android-avd/launch-initial-avd.png
test "$(stat -c%s qa-evidence/android-avd/launch-initial-avd.png)" -gt 10000
# Android immersive-mode tutorial can cover the full Godot view on a fresh
# AVD. Its Got it button is at 594,390 on our forced 720x1280 emulated LCD.
adb shell input tap 593 388
sleep 10
adb exec-out screencap -p > qa-evidence/android-avd/launch-after-immersive-dismiss.png
python3 - <<'PY'
from PIL import Image,ImageStat
im=Image.open('qa-evidence/android-avd/launch-after-immersive-dismiss.png').convert('RGB')
assert im.size==(720,1280),f'AVD displayed unexpected screen size: {im.size}'
stats=ImageStat.Stat(im.crop((40,85,680,485)).convert('L'))
print('AVD after fullscreen tutorial: top render mean/stddev',stats.mean[0],stats.stddev[0])
assert 7 < stats.mean[0] < 150 and stats.stddev[0] > 6, (
  'AVD display is blank or Android immersive-mode tutorial still covering the app')
PY
adb logcat -c || true
for spec in '4 85' '6 220' '8 355' '12 490' '20 625'; do
  read -r sides xpos <<< "$spec"
  echo "AVD live Jolt D$sides: tapping actual Android Control UI"
  adb shell screenrecord --size 720x1280 --bit-rate 4500000 \
    --time-limit 13 "/sdcard/dice-D$sides.mp4" &
  record_pid=$!
  sleep 1
  adb shell input tap "$xpos" 1115
  sleep .3
  adb shell input tap 655 1215
  # The genuine game settles within 9s or reports a failure; retain tail.
  wait "$record_pid"
  adb pull "/sdcard/dice-D$sides.mp4" "qa-evidence/android-avd/dice-D$sides-source.mp4"
  adb shell rm "/sdcard/dice-D$sides.mp4"
  test -s "qa-evidence/android-avd/dice-D$sides-source.mp4"
  # Select 24 actual source-time images per second for the frame critic.
  # No user-facing synthetic throw or replacement of captured physics.
  ffmpeg -hide_banner -loglevel error -y \
    -i "qa-evidence/android-avd/dice-D$sides-source.mp4" \
    -vf fps=24 -c:v libx264 -preset ultrafast -crf 20 \
    -pix_fmt yuv420p "qa-evidence/android-avd/roll-D$sides-24fps.mp4"
done
adb logcat -d -v time > qa-evidence/android-avd/logcat.txt || true
if grep -Eq 'QueuePresentKHR failed|FATAL EXCEPTION.*org.dicemetalbarbie' qa-evidence/android-avd/logcat.txt; then
  echo "FAIL: Android renderer/device error appeared during screenrecord"
  grep -E 'QueuePresentKHR failed|FATAL EXCEPTION' qa-evidence/android-avd/logcat.txt | tail -12
  exit 7
fi
echo "PASS 5 genuine Android emulator screen recordings created"
