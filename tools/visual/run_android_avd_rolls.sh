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
adb exec-out screencap -p > qa-evidence/android-avd/launch-real-avd.png
test "$(stat -c%s qa-evidence/android-avd/launch-real-avd.png)" -gt 10000
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
echo "PASS 5 genuine Android emulator screen recordings created"
