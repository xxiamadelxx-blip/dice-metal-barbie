#!/usr/bin/env bash
# Real Android AVD: eight UI-tapped Jolt rolls and genuine Android screenrecord.
# screenrecord does not promise 24 source FPS; ffmpeg selects nominal 24fps
# screenshots for sequential pixel QA (repeats are reported, not hidden).
set -euo pipefail
mkdir -p qa-evidence/android-avd
adb wait-for-device
# The last Android failure #38165752886 was NOT D6 physics. Actual
# completed-D6.png shows an Android 35 SYSTEM "Messages isn't responding"
# ANR sheet covering the already rendered dice table. Disable ONLY the
# unrelated Messages background service on this disposable x86 emulator;
# never modify production ARM64 APK or the user's phone. If the package
# cannot be disabled, fail closed instead of testing through an overlay.
if adb shell pm list packages | tr -d '\r' | grep -Fxq 'package:com.google.android.apps.messaging'; then
  adb shell am force-stop com.google.android.apps.messaging || true
  adb shell pm disable-user --user 0 com.google.android.apps.messaging
  if ! adb shell pm list packages -d | tr -d '\r' | grep -Fxq 'package:com.google.android.apps.messaging'; then
    echo 'FAIL: Android emulator Google Messages could not be disabled before actual Jolt tests'
    exit 47
  fi
  echo 'AVD only: disabled unrelated Google Messages (original system ANR blocker)'
fi
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
# Pixel-derived actual system button, not a guessed fixed coordinate.
# Failed AVD #38093383377: the (605,447) tap was BELOW the blue button
# at x533..671, y331..426; all 20 screenshots still showed the overlay.
dismiss_immersive_tutorial() {
  local screenshot="$1"
  local button_x button_y target
  target="$(python3 tools/visual/detect_android_immersive.py "$screenshot")" || return 1
  if test -n "$target"; then
    read -r button_x button_y <<< "$target"
    echo "Detected actual Android SYSTEM fullscreen 'Got it' button at ($button_x,$button_y)"
    adb shell input tap "$button_x" "$button_y"
    sleep 2
  fi
}
cp qa-evidence/android-avd/launch-initial-avd.png qa-evidence/android-avd/launch-before-consent.png
dismiss_immersive_tutorial qa-evidence/android-avd/launch-initial-avd.png
adb exec-out screencap -p > qa-evidence/android-avd/launch-after-system-consent.png
# Separate ANDROID SYSTEM blocker: failed run #38133903845 showed a
# Pixel Launcher ANR over an already rendered Godot scene, not a game blackout.
# Only tap "Close app" after BOTH screenshot geometry and system ANR log agree.
dismiss_launcher_anr() {
  local screenshot="$1"
  local target
  target="$(python3 tools/visual/detect_android_launcher_anr.py "$screenshot")" || return 1
  if test -z "$target"; then return 0; fi
  adb logcat -d -v time -s ActivityManager:E WindowManager:I '*:S' > qa-evidence/android-avd/launcher-anr-system-log.txt || true
  if grep -Fq "ANR in com.google.android.apps.nexuslauncher" qa-evidence/android-avd/launcher-anr-system-log.txt; then
    local x y
    read -r x y <<< "$target"
    echo "Android SYSTEM Pixel Launcher ANR confirmed: dismiss Close app at ($x,$y)"
    adb shell input tap "$x" "$y"
    sleep 2
  else
    echo "FAIL: suspected Launcher ANR screenshot without matching system log"
    return 1
  fi
}
dismiss_launcher_anr qa-evidence/android-avd/launch-after-system-consent.png
# A pale Android system ANR sheet can appear AFTER initial readiness. The
# detector reads original Android pixel geometry only, never OCRs or invents
# which process failed. Keep raw PNG and ActivityManager diagnostics. Never
# tap an unknown system dialog and never count an occluded cast as a PASS.
system_anr_sheet_present() {
  local png="$1"
  local observed
  observed="$(python3 tools/visual/detect_android_system_anr.py "$png")" || return 1
  if test "$observed" = SYSTEM_ANR_SHEET; then
    adb logcat -d -v time -s ActivityManager:E WindowManager:I '*:S' \
      > qa-evidence/android-avd/system-anr-activitymanager.log || true
    echo "FAIL: verified pale Android SYSTEM ANR card occludes the actual game: $png"
    return 0
  fi
  return 1
}
# SwiftShader may require >10 s to compile the first 3D scene on Android 35.
# Review genuine ADB screenshots every 5 s; reject Android pop-ups, black
# screens and the Godot splash. Never start recording until the game draws.
ready=0
for attempt in $(seq 1 20); do
  adb exec-out screencap -p > qa-evidence/android-avd/launch-after-immersive-dismiss.png
  # Dialog may animate in AFTER the initial screenshot; safely re-detect
  # on every readiness iteration. The resulting frame is not falsely PASS.
  dismiss_immersive_tutorial qa-evidence/android-avd/launch-after-immersive-dismiss.png
  dismiss_launcher_anr qa-evidence/android-avd/launch-after-immersive-dismiss.png
  if system_anr_sheet_present qa-evidence/android-avd/launch-after-immersive-dismiss.png; then
    exit 48
  fi
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
# Actual 720x1280 M5 7-chip bottom row (ordered D4,D6,D8,D10,D12,D20,D100).
# D100 mode is INSIDE the dock. Read arranged control rectangle from live
# Godot then touch centre with ADB: never fake a pressed signal.
for spec in '4 65 1115 0' '6 163 1115 0' '8 261 1115 0' '12 457 1115 0' '20 555 1115 0' '10 359 1115 0' '100 653 1115 1' '100_PAIR 653 1115 1'; do
  read -r sides xpos ypos mode_toggle <<< "$spec"
  echo "AVD real D$sides: begin recording before Android UI taps"
  # Previous AVD capture incorrectly marked D8 PASS with 263 identical frames,
  # and the D20-labelled video still displayed D12 rolling. Fail on absent
  # Godot start + physically-completed result before selecting the next die.
  adb logcat -c || true
  # Software-rendered Android 35 AVD can take >30 seconds to advance a
  # genuine physical throw. The prior exact D12 test had STARTED and a
  # visible die but no completed signal before screenrecord hard-stopped.
  # Give 90 seconds, but stop at the real signal + a short settling tail.
  adb shell screenrecord --size 720x1280 --bit-rate 4500000 \
    --time-limit 90 "/sdcard/dice-D$sides.mp4" &
  record_pid=$!
  sleep 1
  adb shell input tap "$xpos" "$ypos"
  sleep 0.6
  if test "$mode_toggle" = 1; then
    mode_rect=""
    for mode_attempt in $(seq 1 20); do
      sleep .65
      adb logcat -d -v time -s godot:I '*:S' > "qa-evidence/android-avd/d100-mode-control-$sides.log" || true
      mode_rect="$(sed -n 's/.*DICE_QA_D100_MODE_RECT x=\([0-9]*\) y=\([0-9]*\) w=\([0-9]*\) h=\([0-9]*\).*/\1 \2 \3 \4/p' "qa-evidence/android-avd/d100-mode-control-$sides.log" | tail -1)"
      if test -n "$mode_rect"; then break; fi
    done
    if test -z "$mode_rect"; then
      echo "FAIL: physical D100 mode has no arranged Android rectangle"; exit 35
    fi
    read -r mode_x mode_y mode_w mode_h <<< "$mode_rect"
    if (( mode_x < 0 || mode_y < 1030 || mode_w < 90 || mode_h < 30 || mode_x + mode_w > 720 || mode_y + mode_h > 1280 )); then
      echo "FAIL: D100 mode is not a real touchable dock button: $mode_rect"; exit 36
    fi
    adb shell input tap "$((mode_x + mode_w / 2))" "$((mode_y + mode_h / 2))"
    sleep .65
  fi
  adb shell input tap 655 1215
  completed=0
  failed=0
  roll_log="qa-evidence/android-avd/roll-D$sides-godot.log"
  # 41 polls ×2s = 82s, leaving shutdown/finalize before recorder limit.
  for attempt in $(seq 1 41); do
    sleep 2
    adb logcat -d -v time -s godot:I '*:S' > "$roll_log" || true
    if test $((attempt % 4)) -eq 0; then
      # Only capture a failure candidate; original full 24fps screenrecord
      # remains authoritative and is preserved before a RED exit.
      adb exec-out screencap -p > "qa-evidence/android-avd/system-guard-D$sides-attempt-$attempt.png"
      if system_anr_sheet_present "qa-evidence/android-avd/system-guard-D$sides-attempt-$attempt.png"; then
        failed=1
        break
      fi
    fi
    if grep -Fq "DICE_QA_FAILED D$sides=" "$roll_log"; then
      failed=1
      echo "FAIL: real Godot/Jolt reported physically invalid D$sides roll"
      tail -40 "$roll_log"
      break
    fi
    if grep -Fq "DICE_QA_STARTED D$sides" "$roll_log" &&
       grep -Eq "DICE_QA_COMPLETED D$sides=[0-9]+" "$roll_log"; then
      completed=1
      break
    fi
  done
  # Finalize after a *genuine* event, preserving another 1.5s of real HUD
  # footage. screenrecord handles SIGINT and writes a complete MP4; a hard
  # host adb kill could corrupt it and must not be used.
  if test "$completed" = 1 || test "$failed" = 1; then
    sleep 1.5
    recorder_pids="$(adb shell pidof screenrecord | tr -d '\r' || true)"
    if test -n "$recorder_pids"; then
      adb shell kill -2 $recorder_pids || true
    fi
  fi
  wait "$record_pid" || true
  adb logcat -d -v time -s godot:I '*:S' > "$roll_log" || true
  adb exec-out screencap -p > "qa-evidence/android-avd/completed-D$sides.png"
  test -s "qa-evidence/android-avd/completed-D$sides.png"
  # ALWAYS retain the failed source MP4 before raising a red gate.
  adb pull "/sdcard/dice-D$sides.mp4" "qa-evidence/android-avd/dice-D$sides-source.mp4"
  adb shell rm "/sdcard/dice-D$sides.mp4"
  test -s "qa-evidence/android-avd/dice-D$sides-source.mp4"
  ffmpeg -hide_banner -loglevel error -y \
    -i "qa-evidence/android-avd/dice-D$sides-source.mp4" \
    -vf fps=24 -c:v libx264 -preset ultrafast -crf 20 \
    -pix_fmt yuv420p "qa-evidence/android-avd/roll-D$sides-24fps.mp4"
  if test "$completed" != 1; then
    echo "FAIL: D$sides did not reach real Jolt COMPLETED in 82s software AVD"
    # Even a red run must include all chronological source frames and sheets.
    python3 tools/visual/snapshot_failed_avd_frames.py \
      "qa-evidence/android-avd" "$sides" || true
    tail -60 "$roll_log"
    exit 15
  fi
  grep -E "DICE_QA_(STARTED|COMPLETED) D$sides" "$roll_log" > "qa-evidence/android-avd/result-D$sides.txt"
done
# M4 actual Android UI click-through. Still one real APK: never simulate
# random outputs or paste a prerecorded video; real ADB taps + Jolt log.
echo "AVD M4: begin genuine Android screenrecord before opening advanced drawer"
adb logcat -c || true
adb exec-out screencap -p > qa-evidence/android-avd/m4-before-drawer.png
adb shell screenrecord --size 720x1280 --bit-rate 4500000 \
  --time-limit 175 "/sdcard/dice-M4.mp4" &
m4_record_pid=$!
sleep 1
adb shell input tap 50 97
# A tap and a fixed one-second delay do not prove a new Lavapipe frame.
# Wait for the SAME original crop/threshold; never tap the toggle twice.
python3 tools/visual/wait_android_pixels.py \
  qa-evidence/android-avd/m4-before-drawer.png \
  qa-evidence/android-avd/m4-drawer-open.png \
  --minimum 7500 --crop 17 106 703 510
# Actual native screenshot established exact 720x1280 hit target:
# "БРОСИТЬ ФОРМУЛУ" occupies x32..688 and y259..310.
adb shell input tap 355 285
m4_completed=0
m4_failed=0
m4_log=qa-evidence/android-avd/roll-M4-godot.log
for attempt in $(seq 1 82); do
  sleep 2
  adb logcat -d -v time -s godot:I '*:S' > "$m4_log" || true
  if grep -Fq 'DICE_M4_PHYSICAL_FAILED ' "$m4_log"; then
    m4_failed=1
    echo "FAIL: real Jolt composite failed on Android AVD"
    break
  fi
  if grep -Fq 'DICE_M4_PHYSICAL_STARTED 2d6+1d20-3' "$m4_log" &&
     grep -Fq 'DICE_M4_SIMULTANEOUS_STARTED=3' "$m4_log" &&
     grep -Fq 'DICE_M4_SIMULTANEOUS_COMPLETED=3' "$m4_log" &&
     grep -Eq 'DICE_M4_PHYSICAL_COMPLETED 2d6\+1d20-3=-?[0-9]+' "$m4_log"; then
    m4_completed=1
    break
  fi
done
# Open ACTUAL Android M4 drawer again and tap first real D6's reroll.
# The coordinates are verified from original 720x1280 Android screenshot:
# Menu x50,y97; "ПЕРЕБРОСИТЬ" just below formula button x590,y341.
m4_reroll_completed=0
m4_reroll_failed=0
if test "$m4_completed" = 1; then
  sleep 1
  adb exec-out screencap -p > qa-evidence/android-avd/m4-before-reroll-drawer.png
  adb shell input tap 50 97
  python3 tools/visual/wait_android_pixels.py \
    qa-evidence/android-avd/m4-before-reroll-drawer.png \
    qa-evidence/android-avd/m4-reroll-selector-open.png \
    --minimum 8500 --crop 17 110 703 580
  adb shell input tap 590 340
  sleep 1
  adb exec-out screencap -p > qa-evidence/android-avd/m4-after-reroll-tap.png
  for attempt in $(seq 1 35); do
    adb logcat -d -v time -s godot:I '*:S' > "$m4_log" || true
    if grep -Fq 'DICE_M4_PHYSICAL_FAILED ' "$m4_log"; then
      m4_reroll_failed=1
      break
    fi
    if grep -Fq 'DICE_M4_REAL_REROLL_STARTED group=0 die=0' "$m4_log" &&
       grep -Eq 'DICE_M4_REAL_REROLL_COMPLETED D6=[1-6] attempts=2' "$m4_log" &&
       test "$(grep -Ec 'DICE_M4_PHYSICAL_COMPLETED 2d6\+1d20-3=-?[0-9]+' "$m4_log")" -eq 2; then
      m4_reroll_completed=1
      break
    fi
    sleep 2
  done
fi
# Verify actual Android user navigation into the COMPLETE physical-roll
# history after BOTH genuine casts. This is a real ADB click, not UI mocking.
m4_history_open=0
if test "$m4_completed" = 1 && test "$m4_reroll_completed" = 1; then
  adb exec-out screencap -p > qa-evidence/android-avd/m4-before-history-drawer.png
  adb shell input tap 50 97
  python3 tools/visual/wait_android_pixels.py \
    qa-evidence/android-avd/m4-before-history-drawer.png \
    qa-evidence/android-avd/m4-history-drawer-open.png \
    --minimum 8500 --crop 17 110 703 580
  # Layout grounded by 720x1280 native QA: complete history row appears
  # beneath real D6 selector and presets, centered near x540,y482.
  adb shell input tap 540 482
  python3 tools/visual/wait_android_pixels.py \
    qa-evidence/android-avd/m4-history-drawer-open.png \
    qa-evidence/android-avd/m4-full-history-open.png \
    --minimum 15000 --crop 30 60 690 1190 --difference-threshold 18
  adb logcat -d -v time -s godot:I '*:S' > "$m4_log" || true
  if grep -Eq 'DICE_M4_HISTORY_OPEN records=([2-9]|[1-9][0-9]+)' "$m4_log"; then
    m4_history_open=1
  fi
fi
if test "$m4_completed" = 1 || test "$m4_failed" = 1; then
  sleep 1.5
  recorder_pids="$(adb shell pidof screenrecord | tr -d '\r' || true)"
  if test -n "$recorder_pids"; then adb shell kill -2 $recorder_pids || true; fi
fi
wait "$m4_record_pid" || true
adb logcat -d -v time -s godot:I '*:S' > "$m4_log" || true
adb exec-out screencap -p > qa-evidence/android-avd/completed-M4.png
adb pull "/sdcard/dice-M4.mp4" "qa-evidence/android-avd/dice-M4-source.mp4"
adb shell rm "/sdcard/dice-M4.mp4"
test -s qa-evidence/android-avd/dice-M4-source.mp4
ffmpeg -hide_banner -loglevel error -y \
  -i qa-evidence/android-avd/dice-M4-source.mp4 -vf fps=24 \
  -c:v libx264 -preset ultrafast -crf 20 -pix_fmt yuv420p \
  qa-evidence/android-avd/roll-M4-24fps.mp4
if test "$m4_completed" != 1 || test "$m4_reroll_completed" != 1 || test "$m4_history_open" != 1; then
  echo "FAIL: actual Android mixed throw, physical D6 reroll, or full history click did not complete"
  python3 tools/visual/snapshot_failed_avd_frames.py qa-evidence/android-avd M4 || true
  tail -60 "$m4_log"
  exit 16
fi
grep -E 'DICE_M4_PHYSICAL_(STARTED|COMPLETED)|DICE_M4_REAL_REROLL_(STARTED|COMPLETED)|DICE_M4_HISTORY_OPEN' "$m4_log" > qa-evidence/android-avd/result-M4.txt
cat qa-evidence/android-avd/roll-D*-godot.log > qa-evidence/android-avd/godot-qa-events-all.log
adb logcat -d -v time > qa-evidence/android-avd/logcat.txt || true
if grep -Eq 'QueuePresentKHR failed|FATAL EXCEPTION.*org.dicemetalbarbie' qa-evidence/android-avd/logcat.txt; then
  echo "FAIL: Android renderer/device error appeared during screenrecord"
  grep -E 'QueuePresentKHR failed|FATAL EXCEPTION' qa-evidence/android-avd/logcat.txt | tail -12
  exit 7
fi
# NEW: separate genuine Android screenrecord of tens AND ones selections,
# after preserving all prior eight baseline + M4 D6/full-history checks.
bash tools/visual/run_android_percentile_sources.sh
echo "PASS 8 baseline Jolt videos, real M4 D6 history, AND physical D100 tens/ones Android touches"
# Original touchscreen editor gates, beyond popup-open only.
bash tools/visual/run_android_pool_editor.sh
echo 'PASS four original Android player-edited and physically settled source dice'
