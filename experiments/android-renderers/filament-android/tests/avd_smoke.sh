#!/usr/bin/env bash
set -euo pipefail
out=build/filament-avd-proof
mkdir -p "$out"
apk=build/filament-avd-apk/app-debug.apk
test -s "$apk"
adb install -r "$apk" | tee "$out/installation.txt"
adb shell am start -n com.adeldice.filamentlab/.MainActivity | tee "$out/activity-launch.txt"
sleep 25
adb shell dumpsys activity activities > "$out/activity.txt"
adb exec-out screencap -p > "$out/REAL_NATIVE_FILAMENT_ANDROID_AVD_STARTUP.png"
adb logcat -d -v time > "$out/logcat.txt"
python3 - <<'PY'
from pathlib import Path
import struct,json
p=Path("build/filament-avd-proof/REAL_NATIVE_FILAMENT_ANDROID_AVD_STARTUP.png")
raw=p.read_bytes()
assert raw[:8]==bytes((137,80,78,71,13,10,26,10))
w,h=struct.unpack_from(">II",raw,16)
assert w>=480 and h>=720 and len(raw)>20000,(w,h,len(raw))
act=Path("build/filament-avd-proof/activity.txt").read_text(errors="replace")
assert "com.adeldice.filamentlab" in act,("Filament not active",act[-1000:])
log=Path("build/filament-avd-proof/logcat.txt").read_text(errors="replace")
app_crash=("Process: com.adeldice.filamentlab" in log)
assert not app_crash, "Filament native application crashed, inspect logcat"
print("PASS_REAL_NATIVE_FILAMENT_ANDROID_AVD_START",w,h,len(raw))
Path("build/filament-avd-proof/verification.json").write_text(json.dumps({
 "status":"PASS","app":"Filament fully native","on_actual_emulator":True,
 "original_private_glb_loaded":False,"approved_fixed_camera":"NOT_TESTED",
 "actual_screenshot_size":[w,h]},indent=2)+"\n")
PY
