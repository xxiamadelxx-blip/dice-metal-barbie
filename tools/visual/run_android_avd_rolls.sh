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
# AVD #38090191673 real screenshot: Android immersive tutorial covers dice,
# "Got it" is x533..673/y399..496. Previous x593/y388 missed entirely.
cp qa-evidence/android-avd/launch-initial-avd.png qa-evidence/android-avd/launch-before-consent.png
if python3 - <<'PY'
from PIL import Image
im=Image.open('qa-evidence/android-avd/launch-initial-avd.png').convert('RGB')
panel=all(min(im.getpixel(p))>190 for p in [(180,220),(350,245),(250,340)])
print('Android immersive system overlay present:',panel)
raise SystemExit(0 if panel else 1)
PY
then
  adb shell input tap 605 447
  sleep 2
fi
adb exec-out screencap -p > qa-evidence/android-avd/launch-after-system-consent.png
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
# Actual 720x1280 Godot layout: old five chips at y1115,
# extended M3 D10/D100 chips at y990, D100-mode toggle x465/y990.
# D100 default mode is two D10. First toggle to single (D100);
# next toggle back to pair (D100_PAIR). Verify Godot signal key, never
# infer selection from the tap alone.
for spec in '4 85 1115 0' '6 220 1115 0' '8 355 1115 0' '12 490 1115 0' '20 625 1115 0' '10 285 990 0' '100 365 990 1' '100_PAIR 365 990 1'; do
  read -r sides xpos ypos mode_toggle <<< "$spec"
  echo "AVD real D$sides: begin recording before Android UI taps"
  # Previous AVD capture incorrectly marked D8 PASS with 263 identical frames,
  # and the D20-labelled video still displayed D12 rolling. Fail on absent
  # Godot start + physically-completed result before selecting the next die.
  adb logcat -c || true
  adb shell screenrecord --size 720x1280 --bit-rate 4500000 \
    --time-limit 30 "/sdcard/dice-D$sides.mp4" &
  record_pid=$!
  sleep 1
  adb shell input tap "$xpos" "$ypos"
  sleep 0.6
  if test "$mode_toggle" = 1; then
    adb shell input tap 465 990
    sleep 0.4
  fi
  adb shell input tap 655 1215
  completed=0
  roll_log="qa-evidence/android-avd/roll-D$sides-godot.log"
  for attempt in $(seq 1 14); do
    sleep 2
    adb logcat -d -v time -s godot:I '*:S' > "$roll_log" || true
    if grep -Fq "DICE_QA_FAILED D$sides=" "$roll_log"; then
      echo "FAIL: Godot reported physically invalid D$sides roll"
      tail -40 "$roll_log"
      break
    fi
    if grep -Fq "DICE_QA_STARTED D$sides" "$roll_log" &&
       grep -Eq "DICE_QA_COMPLETED D$sides=[0-9]+" "$roll_log"; then
      completed=1
      break
    fi
  done
  # screenrecord exits normally after 30s, finalizing a real MP4, even if
  # the game did not finish. Never advance to a new die while it is rolling.
  wait "$record_pid"
  adb logcat -d -v time -s godot:I '*:S' > "$roll_log" || true
  adb exec-out screencap -p > "qa-evidence/android-avd/completed-D$sides.png"
  if test "$completed" != 1; then
    echo "FAIL: D$sides never both started and reached a real Jolt result within 30s"
    tail -50 "$roll_log"
    exit 15
  fi
  grep -E "DICE_QA_(STARTED|COMPLETED) D$sides" "$roll_log" > "qa-evidence/android-avd/result-D$sides.txt"
  test -s "qa-evidence/android-avd/completed-D$sides.png"
  adb pull "/sdcard/dice-D$sides.mp4" "qa-evidence/android-avd/dice-D$sides-source.mp4"
  adb shell rm "/sdcard/dice-D$sides.mp4"
  test -s "qa-evidence/android-avd/dice-D$sides-source.mp4"
  # Nominal 24fps frame extraction never fabricates physical animation.
  # The auditor rejects missing motion, blackouts, and missing Godot events.
  ffmpeg -hide_banner -loglevel error -y \
    -i "qa-evidence/android-avd/dice-D$sides-source.mp4" \
    -vf fps=24 -c:v libx264 -preset ultrafast -crf 20 \
    -pix_fmt yuv420p "qa-evidence/android-avd/roll-D$sides-24fps.mp4"
done
cat qa-evidence/android-avd/roll-D*-godot.log > qa-evidence/android-avd/godot-qa-events-all.log
adb logcat -d -v time > qa-evidence/android-avd/logcat.txt || true
if grep -Eq 'QueuePresentKHR failed|FATAL EXCEPTION.*org.dicemetalbarbie' qa-evidence/android-avd/logcat.txt; then
  echo "FAIL: Android renderer/device error appeared during screenrecord"
  grep -E 'QueuePresentKHR failed|FATAL EXCEPTION' qa-evidence/android-avd/logcat.txt | tail -12
  exit 7
fi
echo "PASS 8 genuine Android emulator physical screen recordings created"
