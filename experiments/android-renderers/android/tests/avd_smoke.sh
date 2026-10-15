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
# Keep initial evidence, including transient emulator/launcher ANR overlays.
adb exec-out screencap -p > "$OUT_DIR/REAL_ANDROID_INITIAL_UNFILTERED.png"

dump_window() {
  local name="$1"
  timeout 35 adb shell uiautomator dump /sdcard/dice_m5_window.xml > "$OUT_DIR/$name-dump.log" 2>&1 || true
  timeout 10 adb pull /sdcard/dice_m5_window.xml "$OUT_DIR/$name.xml" > /dev/null 2>&1 || true
}
dump_window "before"

# The first AVD attempt passed PNG-only validation but its screenshot visibly
# contained "Pixel Launcher isn't responding". A modal SYSTEM ERROR is not a
# valid visual QA frame. Dismiss a transient launcher's "Wait" dialog only when
# the actual Android accessibility bounds prove which button is present.
python3 - <<'PY'
import re
from pathlib import Path
from xml.etree import ElementTree
p=Path("build/avd-original-pixels/before.xml")
target=Path("build/avd-original-pixels/dismiss.tap")
if not p.is_file():
    print("AVD_A11Y_DUMP_MISSING: clean capture will still be checked")
else:
    root=ElementTree.parse(p)
    elements=list(root.iter("node"))
    labelled=[(n.attrib.get("text","")+" "+n.attrib.get("content-desc","")).strip() for n in elements]
    visible=" ".join(labelled)
    error=("isn't responding" in visible or "не отвечает" in visible or "Close app" in visible)
    print("AVD_SYSTEM_DIALOG_FROM_ACCESSIBILITY",error)
    if error:
        for n in elements:
            label=n.attrib.get("text","")
            if label in ("Wait","Подождать","Wait for response","Ожидать"):
                b=re.findall(r"\[(\d+),(\d+)\]",n.attrib.get("bounds",""))
                if len(b)==2:
                    x=(int(b[0][0])+int(b[1][0]))//2
                    y=(int(b[0][1])+int(b[1][1]))//2
                    target.write_text(f"{x} {y}\n")
                    print("AVD_DISMISS_LAUNCHER_DIALOG_BY_VERIFIED_BOUNDS",x,y)
                    break
        else:
            raise AssertionError("ANR overlay detected; cannot identify actual Wait button safely")
PY
if test -s "$OUT_DIR/dismiss.tap"; then
    read -r X Y < "$OUT_DIR/dismiss.tap"
    adb shell input tap "$X" "$Y"
    sleep 12
fi
# Relaunch focus to our APK, not Pixel Launcher, then capture after UI redraw.
adb shell am start -n com.adeldice.threelab/.MainActivity > "$OUT_DIR/relaunch.txt"
sleep 8
adb shell dumpsys activity activities > "$OUT_DIR/activity.txt"
adb exec-out screencap -p > "$OUT_DIR/REAL_ANDROID_EMULATOR_THREE_APP_SCREEN.png"
dump_window "after"
adb logcat -d -v threadtime > "$OUT_DIR/logcat.txt"

python3 - <<'PY'
from pathlib import Path
from xml.etree import ElementTree
import struct
out=Path("build/avd-original-pixels")
p=out/"REAL_ANDROID_EMULATOR_THREE_APP_SCREEN.png"
raw=p.read_bytes()
assert raw[:8]==bytes((137,80,78,71,13,10,26,10))
width,height=struct.unpack_from(">II",raw,16)
assert width>=480 and height>=720 and len(raw)>25000,(width,height,len(raw))
activity=(out/"activity.txt").read_text(errors="replace")
assert "com.adeldice.threelab" in activity,"Our activity absent"
log=(out/"logcat.txt").read_text(errors="replace")
assert "FATAL EXCEPTION" not in "\n".join(x for x in log.splitlines() if "com.adeldice.threelab" in x)
p=out/"after.xml"
if p.is_file():
    root=ElementTree.parse(p)
    visible=" ".join((n.attrib.get("text","")+" "+n.attrib.get("content-desc",""))
                     for n in root.iter("node"))
    assert not ("isn't responding" in visible or "не отвечает" in visible or "Close app" in visible),(
        "Emulator still covered by SYSTEM NOT RESPONDING dialog; screenshot rejected")
    print("AVD_NO_SYSTEM_ANR_OVERLAY_ACCESSIBILITY_PASS")
else:
    print("AVD_A11Y_NOT_AVAILABLE: cannot guarantee no system overlay; screenshot for visual review")
print("PASS_REAL_ANDROID_EMULATOR_APP_SCREEN_AND_INSTALL",width,height,len(raw))
PY


# Real Android UI interaction, not only a WebGL startup screenshot.
# Android uiautomator exposed the browser DOM node "Бросить D20" and exact
# clickable bounds in previous AVD run #38658823402.
python3 - <<'PY'
from pathlib import Path
from xml.etree import ElementTree
import re
out=Path("build/avd-original-pixels")
root=ElementTree.parse(out/"after.xml")
buttons=[n for n in root.iter("node") if n.attrib.get("text","")=="Бросить D20"]
assert len(buttons)==1,("RNG-first D20 button not exposed in Android accessibility",len(buttons))
b=re.findall(r"\[(\d+),(\d+)\]",buttons[0].attrib.get("bounds",""))
assert len(b)==2,("RNG-first control is offscreen",b)
x=(int(b[0][0])+int(b[1][0]))//2
y=(int(b[0][1])+int(b[1][1]))//2
assert x>50 and 50<y<2390,("Invalid viewport control bounds",x,y)
(out/"roll.tap").write_text(f"{x} {y}\n")
print("PASS_ANDROID_VISIBLE_RNG_BUTTON_BOUNDS",x,y)
PY
read -r RX RY < "$OUT_DIR/roll.tap"
adb shell input tap "$RX" "$RY"
sleep 12
dump_window "after-rng-roll"
adb exec-out screencap -p > "$OUT_DIR/REAL_ANDROID_RNG_FIRST_D20_AFTER_ROLL.png"
python3 - <<'PY'
from pathlib import Path
from xml.etree import ElementTree
import re,struct,json
out=Path("build/avd-original-pixels")
p=out/"after-rng-roll.xml"
assert p.is_file(), "No Android accessibility results after tapping actual D20"
root=ElementTree.parse(p)
visible=" ".join((n.attrib.get("text","")+" "+n.attrib.get("content-desc",""))
                 for n in root.iter("node"))
assert "isn't responding" not in visible and "Close app" not in visible,(
    "Android screenshot covered with system ANR")
m=re.search(r"D20=(\d+); сумма (\d+)\. Видимая грань D20: (\d+)\.",visible)
assert m,("Android WebView did not settle with displayed RNG+gold face parity",visible[-1000:])
rng,total,visible_face=map(int,m.groups())
assert 1<=rng<=20 and total==rng==visible_face,(rng,total,visible_face)
png=(out/"REAL_ANDROID_RNG_FIRST_D20_AFTER_ROLL.png").read_bytes()
assert png[:8]==bytes((137,80,78,71,13,10,26,10))
w,h=struct.unpack_from(">II",png,16)
assert w>=480 and h>=720 and len(png)>25000,(w,h,len(png))
data={"result_from_crypto":rng,"visually_upward_number":visible_face,
      "webview_displayed_total":total,"actual_android_emulator":True,
      "scripted_quaternion_animation_not_real_rigidbody":True,
      "original_owner_blenderkit_glb":False,
      "screenshot":str(out/"REAL_ANDROID_RNG_FIRST_D20_AFTER_ROLL.png")}
(out/"real_android_rng_roll_assertions.json").write_text(json.dumps(data,indent=2)+"\n")
print("PASS_REAL_ANDROID_EMULATOR_RNG_FIRST_D20_VISIBLE_FACE",json.dumps(data))
PY
