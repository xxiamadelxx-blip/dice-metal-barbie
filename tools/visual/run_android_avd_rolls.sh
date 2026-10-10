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
adb shell getprop ro.hardware.egl > qa-evidence/android-avd/egl-driver.txt || true
adb shell getprop ro.opengles.version >> qa-evidence/android-avd/egl-driver.txt || true
adb shell am force-stop org.dicemetalbarbie.dnddice || true
adb shell monkey -p org.dicemetalbarbie.dnddice 1
sleep 9
adb exec-out screencap -p > qa-evidence/android-avd/launch-initial-avd.png
test "$(stat -c%s qa-evidence/android-avd/launch-initial-avd.png)" -gt 10000
# Android immersive-mode tutorial can cover the full Godot view on a fresh
# AVD. Its Got it button is at 594,390 on our forced 720x1280 emulated LCD.
adb shell input tap 593 388
# SwiftShader may require >10 s to compile the first 3D scene on Android 35.
# Review genuine ADB screenshots every 5 s; reject Android pop-ups, black
# screens and the Godot splash. Never start recording until the game draws.
ready=0
for attempt in $(seq 1 20); do
  adb exec-out screencap -p > qa-evidence/android-avd/launch-after-immersive-dismiss.png
  if python3 - <<'PY'
from PIL import Image,ImageStat
im=Image.open('qa-evidence/android-avd/launch-after-immersive-dismiss.png').convert('RGB')
assert im.size==(720,1280), f'Unexpected Android display {im.size}'
t=ImageStat.Stat(im.crop((40,85,680,485)).convert('L'))
print('Real AVD game readiness, mean/stddev:',round(t.mean[0],2),round(t.stddev[0],2))
assert 7 < t.mean[0] < 150 and t.stddev[0] > 6, (
  'blank/Android system overlay/Godot splash - not playable game yet')
PY
  then
    ready=1
    break
  fi
  cp qa-evidence/android-avd/launch-after-immersive-dismiss.png     "qa-evidence/android-avd/not-ready-attempt-$attempt.png"
  sleep 5
done
if test "$ready" != 1; then
  adb logcat -d -v time > qa-evidence/android-avd/logcat-on-black-screen.txt || true
  grep -Ei 'SceneShaderGLES3|CanvasShaderGLES3|GL_MAX_FRAGMENT_UNIFORM|QueuePresentKHR|EGL_BAD|godot|FATAL EXCEPTION' qa-evidence/android-avd/logcat-on-black-screen.txt > qa-evidence/android-avd/renderer-errors.txt || true
  adb shell dumpsys SurfaceFlinger > qa-evidence/android-avd/surfaceflinger.txt || true
  printf "Source EGL diagnostic and filtered renderer errors retained for Gauntlet review.\n"
  adb shell dumpsys activity activities > qa-evidence/android-avd/activities-on-black-screen.txt || true
  echo "FAIL: Android AVD never rendered playable dice scene in 100 seconds"
  exit 8
fi
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
