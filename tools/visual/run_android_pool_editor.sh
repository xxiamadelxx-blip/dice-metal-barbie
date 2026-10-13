#!/usr/bin/env bash
# New M4 pool-editor Android AVD player touch walkthrough, after 8 baseline
# real Jolt captures and actual selected D100 tens/ones. Not phone FPS proof.
set -euo pipefail
out=qa-evidence/android-avd
device=/sdcard/dice-M4-POOL.mp4
raw="$out/dice-M4-POOL-source.mp4"
film="$out/roll-M4-POOL-24fps.mp4"
log="$out/roll-M4-POOL-godot.log"
mkdir -p "$out"
recording=""
cleanup() {
  local status=$?
  if test -n "$recording"; then
    active="$(adb shell pidof screenrecord | tr -d '\r' || true)"
    if test -n "$active"; then adb shell kill -2 $active || true; fi
    wait "$recording" || true
    recording=""
  fi
  adb logcat -d -v time -s godot:I '*:S' > "$log" || true
  adb exec-out screencap -p > "$out/m4-pool-original-final.png" || true
  adb pull "$device" "$raw" || true
  adb shell rm "$device" || true
  if test -s "$raw"; then
    ffmpeg -hide_banner -loglevel error -y -i "$raw" -vf fps=24 \
      -c:v libx264 -preset ultrafast -crf 20 -pix_fmt yuv420p "$film" || true
  fi
  if test "$status" -ne 0 && test -s "$film"; then
    python3 tools/visual/snapshot_failed_avd_frames.py "$out" M4-POOL || true
  fi
}
trap cleanup EXIT
# Require a NEW Godot main scene. Reused Android buffer pixels from a prior
# history modal are not evidence of this app having launched correctly.
adb logcat -c || true
adb shell am force-stop org.dicemetalbarbie.dnddice
adb shell monkey -p org.dicemetalbarbie.dnddice 1
stage=0
for attempt in $(seq 1 20); do
  adb logcat -d -v time -s godot:I '*:S' > "$out/m4-pool-fresh-process.log" || true
  adb exec-out screencap -p > "$out/m4-pool-original-before-drawer.png"
  if grep -Fq 'DICE_QA_MAIN_SCENE_READY' "$out/m4-pool-fresh-process.log" &&
      python3 - "$out/m4-pool-original-before-drawer.png" <<'PY'
from PIL import Image,ImageStat
import sys
im=Image.open(sys.argv[1]).convert('RGB')
assert im.size==(720,1280)
m=ImageStat.Stat(im.crop((40,85,680,485)).convert('L'))
print('M4 original Android pool READY mean/std:',round(m.mean[0],2),round(m.stddev[0],2))
assert 7<m.mean[0]<150 and m.stddev[0]>6,'Not the playable original Godot stage'
PY
  then stage=1; break; fi
  cp "$out/m4-pool-original-before-drawer.png" "$out/m4-pool-not-ready-$attempt.png"
  sleep 5
done
if test "$stage" != 1; then echo 'FAIL: no fresh playable Android dice table for pool'; exit 51; fi
adb logcat -c || true
adb shell screenrecord --size 720x1280 --bit-rate 4500000 --time-limit 175 "$device" &
recording=$!
sleep 1
# One ACTUAL Android player tap to the previously accepted hamburger.
adb shell input tap 50 97
drawer=0
for attempt in $(seq 1 15); do
  sleep .8
  adb exec-out screencap -p > "$out/m4-pool-original-drawer.png"
  if python3 - "$out/m4-pool-original-before-drawer.png" "$out/m4-pool-original-drawer.png" <<'PY'
from PIL import Image,ImageChops
import sys
a=Image.open(sys.argv[1]).convert('RGB')
b=Image.open(sys.argv[2]).convert('RGB')
assert a.size==b.size==(720,1280)
d=ImageChops.difference(a.crop((17,110,703,580)),b.crop((17,110,703,580))).convert('L')
different=sum(n for v,n in enumerate(d.histogram()) if v>16)
print('M4 pool real Android drawer pixels:',different)
assert different>8500,'Wait for truly displayed advanced drawer'
PY
  then drawer=1; break; fi
  cp "$out/m4-pool-original-drawer.png" "$out/m4-pool-drawer-wait-$attempt.png"
done
if test "$drawer" != 1; then echo 'FAIL: actual editor parent drawer not visible'; exit 52; fi
# The new 84x46 "НАБОР" button is in the original formula input's x604..688
# right end at y~175, without moving the previously accepted throw controls.
adb shell input tap 632 175
popup=0
for attempt in $(seq 1 20); do
  sleep .8
  adb exec-out screencap -p > "$out/m4-pool-original-dialog.png"
  adb logcat -d -v time -s godot:I '*:S' > "$log" || true
  if grep -Fq 'DICE_M4_POOL_EDITOR_OPEN formula=2d6+1d20-3' "$log" &&
     python3 - "$out/m4-pool-original-drawer.png" "$out/m4-pool-original-dialog.png" <<'PY'
from PIL import Image,ImageChops
import sys
a=Image.open(sys.argv[1]).convert('RGB')
b=Image.open(sys.argv[2]).convert('RGB')
assert a.size==b.size==(720,1280)
d=ImageChops.difference(a.crop((40,190,680,1140)),b.crop((40,190,680,1140))).convert('L')
different=sum(n for v,n in enumerate(d.histogram()) if v>18)
print('M4 pool ACTUAL dialog visible changed original pixels:',different)
assert different>15000,'Godot window telemetry alone not sufficient: dialog pixels missing'
PY
  then popup=1; break; fi
  cp "$out/m4-pool-original-dialog.png" "$out/m4-pool-dialog-wait-$attempt.png"
done
if test "$popup" != 1; then echo 'FAIL: player physical pool editor popup never rendered'; exit 53; fi
# Keep at least 5 seconds of full source frames after the popup appears.
sleep 5
adb logcat -d -v time -s godot:I '*:S' > "$log" || true
# Merely opening and inspecting a draft MUST NOT physically throw or
# replace any stored original Jolt face, result or existing history.
if grep -Eq 'DICE_M4_POOL_APPLIED|DICE_M4_PHYSICAL_STARTED' "$log"; then
  echo 'FAIL: opening the editor implicitly applied a draft or started Jolt'
  exit 54
fi
# SECOND REAL-ANDROID INTERACTION ROUND: add/remove, flip physical group sign
# twice, CANCEL pending draft, reopen original persistent valid expression.
# Coordinates derived from exact original successful AVD full-height screenshot
# #38164276191, not a programmatically emitted pressed() signal or a mock.
# Both conditions MUST hold for each click: Godot emitted the exact edit AND
# a later ADB screenshot contains distinct rendered pixels versus the prior
# accepted state. ADB/Godot logcat can precede GPU framebuffer presentation.
# Use the IDENTICAL full-resolution ROI/threshold as the offline frame auditor.
pool_pixels_changed() {
  python3 tools/visual/check_pool_editor_pixels.py "$out/$1" "$out/$2" --minimum 75
}
touch_pool_event() {
  local wanted="$1" occurrences="$2" filename="$3" failure="$4" previous="$5" found=0
  for attempt in $(seq 1 20); do
    sleep .65
    adb logcat -d -v time -s godot:I '*:S' > "$log" || true
    adb exec-out screencap -p > "$out/$filename"
    found="$(grep -Fc "$wanted" "$log" || true)"
    if test "$found" -ge "$occurrences" &&
       pool_pixels_changed "$previous" "$filename"; then
      echo "PASS Android rendered editor change after actual touch: $wanted"
      return 0
    fi
  done
  echo "FAIL: Android touch event and distinct pixels were not both observed: $wanted"
  exit "$failure"
}
# D4 is the genuine initial OptionButton group die type. Add third PHYSICAL D4.
adb shell input tap 524 514
touch_pool_event 'DICE_M4_POOL_EDIT formula=2d6+1d20+1d4-3' 1 \
  m4-pool-original-added-d4.png 62 m4-pool-original-dialog.png
# The added third group is selected. Remove it with the real row hitbox.
adb shell input tap 601 566
touch_pool_event 'DICE_M4_POOL_EDIT formula=2d6+1d20-3' 1 \
  m4-pool-original-removed-d4.png 63 m4-pool-original-added-d4.png
# Select the second ORIGINAL D20 group and flip its signed contribution.
adb shell input tap 135 340
sleep .6
adb shell input tap 437 565
touch_pool_event 'DICE_M4_POOL_EDIT formula=2d6-1d20-3' 1 \
  m4-pool-original-negative-d20.png 64 m4-pool-original-removed-d4.png
# Undo the negative sign with ANOTHER real touch; this is not a saved roll.
adb shell input tap 437 565
touch_pool_event 'DICE_M4_POOL_EDIT formula=2d6+1d20-3' 2 \
  m4-pool-original-restored-d20.png 65 m4-pool-original-negative-d20.png
# Real Cancel must discard the modal and leave the underlying formula alone.
adb shell input tap 200 1000
cancel_rendered=0
for attempt in $(seq 1 20); do
  sleep .65
  adb exec-out screencap -p > "$out/m4-pool-original-after-cancel.png"
  if pool_pixels_changed m4-pool-original-restored-d20.png m4-pool-original-after-cancel.png; then
    cancel_rendered=1; break
  fi
done
if test "$cancel_rendered" != 1; then
  echo 'FAIL: Cancel has not visibly dismissed Android editor'; exit 66
fi
adb logcat -d -v time -s godot:I '*:S' > "$log" || true
if grep -Eq 'DICE_M4_POOL_APPLIED|DICE_M4_PHYSICAL_STARTED' "$log"; then
  echo 'FAIL: Android Cancel applied draft or launched Jolt'
  exit 66
fi
# Reopen via actual touchscreen. Re-emitted original formula is ground truth
# that cancel did NOT apply any editor draft to the active physical pool.
adb shell input tap 632 175
reopened=0
for attempt in $(seq 1 14); do
  sleep .7
  adb logcat -d -v time -s godot:I '*:S' > "$log" || true
  adb exec-out screencap -p > "$out/m4-pool-original-reopened-after-cancel.png"
  opens="$(grep -Fc 'DICE_M4_POOL_EDITOR_OPEN formula=2d6+1d20-3' "$log" || true)"
  if test "$opens" -ge 2 &&
     pool_pixels_changed m4-pool-original-after-cancel.png m4-pool-original-reopened-after-cancel.png; then
    reopened=1; break
  fi
done
if test "$reopened" != 1; then
  echo 'FAIL: real Android Cancel did not preserve original formula on reopen'
  exit 67
fi
# Existing final test still MUST change D6 quantity/modifier, Apply, throw
# four TRUE rigid bodies and open actual saved history.
# Real 720x1280 screenshot from prior native Jolt visual Gauntlet placed
# D6 group count +1 near (280,565); flat modifier +1 near (573,618).
adb shell input tap 280 565
count_ok=0
for attempt in $(seq 1 12); do
  sleep .65
  adb logcat -d -v time -s godot:I '*:S' > "$log" || true
  adb exec-out screencap -p > "$out/m4-pool-original-count-changed.png"
  if grep -Fq 'DICE_M4_POOL_EDIT formula=3d6+1d20-3' "$log" &&
     pool_pixels_changed m4-pool-original-reopened-after-cancel.png m4-pool-original-count-changed.png; then
    count_ok=1; break
  fi
done
if test "$count_ok" != 1; then echo 'FAIL: Android did not increment physical D6 source count'; exit 55; fi
adb shell input tap 573 618
mod_ok=0
for attempt in $(seq 1 12); do
  sleep .65
  adb logcat -d -v time -s godot:I '*:S' > "$log" || true
  adb exec-out screencap -p > "$out/m4-pool-original-modifier-changed.png"
  if grep -Fq 'DICE_M4_POOL_EDIT formula=3d6+1d20-2' "$log" &&
     pool_pixels_changed m4-pool-original-count-changed.png m4-pool-original-modifier-changed.png; then
    mod_ok=1; break
  fi
done
if test "$mod_ok" != 1; then echo 'FAIL: Android modifier button not touched'; exit 56; fi
# Bottom native dialog is ACTUALLY visible after wrap_controls=false.
adb shell input tap 460 1000
apply_ok=0
for attempt in $(seq 1 16); do
  sleep .65
  adb logcat -d -v time -s godot:I '*:S' > "$log" || true
  adb exec-out screencap -p > "$out/m4-pool-original-after-apply.png"
  if grep -Fq 'DICE_M4_POOL_APPLIED formula=3d6+1d20-2' "$log" &&
     pool_pixels_changed m4-pool-original-modifier-changed.png m4-pool-original-after-apply.png; then
    apply_ok=1; break
  fi
done
if test "$apply_ok" != 1; then echo 'FAIL: actual Android Apply footer did not modify formula'; exit 57; fi
# Applying must NOT launch Jolt. The next ACTUAL Throw click does.
if grep -Fq 'DICE_M4_PHYSICAL_STARTED' "$log"; then
  echo 'FAIL: applying a pool unexpectedly triggered Jolt'; exit 58
fi
# Independent Qwen 7B source critique: applying alone doesn't prove that a
# NEW modal reloads the edited formula. Reopen using the same real touchscreen
# button, demand the EXACT newly persisted formula and distinct Android pixels.
adb shell input tap 632 175
applied_reopened=0
for attempt in $(seq 1 20); do
  sleep .65
  adb logcat -d -v time -s godot:I '*:S' > "$log" || true
  adb exec-out screencap -p > "$out/m4-pool-original-applied-reopened.png"
  if grep -Fq 'DICE_M4_POOL_EDITOR_OPEN formula=3d6+1d20-2' "$log" &&
     pool_pixels_changed m4-pool-original-after-apply.png m4-pool-original-applied-reopened.png; then
    applied_reopened=1; break
  fi
done
if test "$applied_reopened" != 1; then
  echo 'FAIL: re-opened Android editor did not show newly applied pool'; exit 69
fi
# Close without modifying the draft and prove a second Apply did not happen.
adb shell input tap 200 1000
applied_cancel_visible=0
for attempt in $(seq 1 20); do
  sleep .65
  adb exec-out screencap -p > "$out/m4-pool-original-after-applied-reopen-cancel.png"
  if pool_pixels_changed m4-pool-original-applied-reopened.png m4-pool-original-after-applied-reopen-cancel.png; then
    applied_cancel_visible=1; break
  fi
done
if test "$applied_cancel_visible" != 1; then
  echo 'FAIL: applied-formula recheck modal did not visibly dismiss'; exit 70
fi
adb logcat -d -v time -s godot:I '*:S' > "$log" || true
if test "$(grep -Fc 'DICE_M4_POOL_APPLIED formula=3d6+1d20-2' "$log" || true)" != 1 ||
   grep -Fq 'DICE_M4_PHYSICAL_STARTED' "$log"; then
  echo 'FAIL: reopening/cancelling the applied formula changed pool or rolled'; exit 71
fi
adb shell input tap 355 285
physical_ok=0
for attempt in $(seq 1 105); do
  sleep 1
  adb logcat -d -v time -s godot:I '*:S' > "$log" || true
  if grep -Fq 'DICE_M4_PHYSICAL_FAILED ' "$log"; then
    echo 'FAIL: actual pool threw physically invalid faces'; exit 59
  fi
  if grep -Fq 'DICE_M4_PHYSICAL_STARTED 3d6+1d20-2' "$log" &&
     grep -Fq 'DICE_M4_SIMULTANEOUS_STARTED=4' "$log" &&
     grep -Fq 'DICE_M4_SIMULTANEOUS_COMPLETED=4' "$log" &&
     grep -Eq 'DICE_M4_PHYSICAL_COMPLETED 3d6\+1d20-2=[0-9]+' "$log"; then
    physical_ok=1; break
  fi
done
if test "$physical_ok" != 1; then
  echo 'FAIL: edited four Jolt physical bodies never completed'; exit 60
fi
adb exec-out screencap -p > "$out/m4-pool-original-physical-result.png"
adb shell input tap 50 97
sleep 1
adb exec-out screencap -p > "$out/m4-pool-original-history-drawer.png"
adb shell input tap 540 482
history_ok=0
for attempt in $(seq 1 12); do
  sleep .7
  adb logcat -d -v time -s godot:I '*:S' > "$log" || true
  adb exec-out screencap -p > "$out/m4-pool-original-saved-history.png"
  if grep -Eq 'DICE_M4_HISTORY_OPEN records=([1-9]|[1-9][0-9]+)' "$log"; then
    history_ok=1; break
  fi
done
if test "$history_ok" != 1; then echo 'FAIL: offline four-body receipt popup absent'; exit 61; fi
sleep 1
cleanup
trap - EXIT
test -s "$film"
echo 'PASS real Android count/modifier Apply, four actual Jolt bodies and saved history'
