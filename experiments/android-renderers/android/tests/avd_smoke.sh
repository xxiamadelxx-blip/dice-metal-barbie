#!/usr/bin/env bash
set -euo pipefail
OUT_DIR="${AVD_EVIDENCE:-build/avd-original-pixels}"
mkdir -p "$OUT_DIR"
APK="${WEBVIEW_APK_PATH:-build/avd-apk/app-debug.apk}"
test -s "$APK"
adb devices -l | tee "$OUT_DIR/device.txt"
adb install -r "$APK" | tee "$OUT_DIR/install.txt"
adb shell am start -n com.adeldice.threelab/.MainActivity | tee "$OUT_DIR/launch.txt"
sleep 22
adb shell dumpsys activity activities > "$OUT_DIR/activity.txt"
grep -F "com.adeldice.threelab" "$OUT_DIR/activity.txt" | head -10
adb exec-out screencap -p > "$OUT_DIR/REAL_ANDROID_EMULATOR_THREE_APP_SCREEN.png"
adb logcat -d -v threadtime > "$OUT_DIR/logcat.txt"
python3 - <<'PY'
from pathlib import Path
import struct
p=Path("build/avd-original-pixels/REAL_ANDROID_EMULATOR_THREE_APP_SCREEN.png")
raw=p.read_bytes()
assert raw[:8]==bytes((137,80,78,71,13,10,26,10))
width,height=struct.unpack_from(">II",raw,16)
assert width>=480 and height>=720 and len(raw)>25000,(width,height,len(raw))
log=Path("build/avd-original-pixels/logcat.txt").read_text(errors="replace")
assert "FATAL EXCEPTION" not in "\n".join(x for x in log.splitlines() if "com.adeldice.threelab" in x)
print("PASS_REAL_ANDROID_EMULATOR_APP_SCREEN_AND_INSTALL",width,height,len(raw))
PY
