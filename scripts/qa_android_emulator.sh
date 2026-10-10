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
sleep 9
capture 01-launch
if ! adb shell pidof "$package" > qa-evidence/app-pid.txt; then
  echo "App terminated after launch" | tee qa-evidence/FAIL.txt
  exit 3
fi
# User-equivalent tap on the button in the bottom control dock.
adb shell input tap 360 1115
sleep 3
capture 02-throw-motion
sleep 10
capture 03-after-throw
adb shell input tap 360 1048
sleep 2
capture 04-dice-picker
echo "Emulator QA capture completed. Visual review still required." | tee qa-evidence/completed.txt
