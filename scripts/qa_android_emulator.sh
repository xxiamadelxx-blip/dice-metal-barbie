#!/usr/bin/env bash
# Cloud device-level visual QA for the real Godot APK, without any user phone.
set -Eeuo pipefail
mkdir -p qa-evidence
package="org.dicemetalbarbie.dnddice"
apk="${1:-build/apk/dice-3d-m3-d4-debug.apk}"
echo "APK: $apk" | tee qa-evidence/session.txt
echo "UTC: $(date -u -Iseconds)" >> qa-evidence/session.txt
adb shell getprop ro.product.cpu.abilist | tee qa-evidence/emulator-abis.txt
adb shell getprop ro.dalvik.vm.native.bridge | tee qa-evidence/native-bridge.txt
adb shell wm size 720x1280
adb shell wm density 320
adb shell settings put system accelerometer_rotation 0
adb shell settings put system user_rotation 0
# Suppress Android immersive-mode first-launch confirmation, not a game element.
adb shell settings put secure immersive_mode_confirmations confirmed || true
adb logcat -c

capture() {
  local name="$1"
  adb exec-out screencap -p > "qa-evidence/${name}.png"
  adb shell dumpsys window windows > "qa-evidence/${name}-windows.txt" || true
  echo "Captured ${name}.png"
}
collect() {
  adb logcat -d -v time > qa-evidence/logcat.txt || true
  adb shell dumpsys activity activities > qa-evidence/activities.txt || true
  adb shell pm list packages | grep -F "$package" > qa-evidence/installed-package.txt || true
}
trap collect EXIT

echo "Installing the real Android APK..."
if ! adb install -r "$apk" 2>&1 | tee qa-evidence/install.txt; then
  echo "APK install failed (check CPU ABI and native bridge)" | tee qa-evidence/FAIL.txt
  capture install-failure || true
  exit 2
fi
adb shell pm path "$package" > qa-evidence/package-path.txt
adb shell monkey -p "$package" -c android.intent.category.LAUNCHER 1 > qa-evidence/launch.txt 2>&1
sleep 24
capture 00-before-system-overlay-dismiss
# Fresh Android emulator may still show a system full-screen tutorial;
# tap its Got it button before evaluating the actual rendered app.
adb shell input tap 590 380
sleep 4
capture 01-launch
if ! adb shell pidof "$package" > qa-evidence/app-pid.txt; then
  echo "App terminated after launch" | tee qa-evidence/FAIL.txt
  exit 3
fi
# User-equivalent tap on the button in the bottom control dock.
adb shell input tap 360 1115
sleep 5
capture 02-throw-motion
sleep 12
capture 03-after-throw
adb shell input tap 360 1048
sleep 2
capture 04-dice-picker
# Reject a uniformly black surface or a screenshot unchanged by interactions.
launch_bytes=$(stat -c%s qa-evidence/01-launch.png)
result_bytes=$(stat -c%s qa-evidence/03-after-throw.png)
echo "launch_png_bytes=$launch_bytes after_throw_png_bytes=$result_bytes" | tee qa-evidence/pixel-checks.txt
if (( launch_bytes < 9000 || result_bytes < 9000 )); then
  echo "FAIL: blank/near-uniform screenshot; inspect rendering logcat" | tee qa-evidence/FAIL.txt
  exit 4
fi
if cmp -s qa-evidence/01-launch.png qa-evidence/03-after-throw.png; then
  echo "FAIL: no visible change after user tap/throw" | tee qa-evidence/FAIL.txt
  exit 5
fi
echo "Emulator visual smoke PASS (nonblank frames changed); review still required." | tee qa-evidence/completed.txt
