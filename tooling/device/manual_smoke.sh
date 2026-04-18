#!/bin/zsh
set -euo pipefail

DEVICE="${1:-e4195adb}"
UI_XML=/tmp/aura_manual.xml
HELPER="/Users/haoc/Developer/aura/tooling/device/aura_ui_helpers.py"

dump_ui() {
  adb -s "$DEVICE" shell uiautomator dump /sdcard/aura_manual.xml >/dev/null
  adb -s "$DEVICE" shell cat /sdcard/aura_manual.xml > "$UI_XML"
}

wait_for_desc() {
  local needle="$1"
  local timeout="${2:-60}"
  local start=$(date +%s)

  while true; do
    dump_ui
    if [ "$(python3 "$HELPER" "$UI_XML" exists_desc "$needle")" = "1" ]; then
      return 0
    fi
    if [ $(( $(date +%s) - start )) -ge "$timeout" ]; then
      echo "Timed out waiting for desc: $needle" >&2
      return 1
    fi
    sleep 1
  done
}

get_desc_center() {
  python3 "$HELPER" "$UI_XML" desc "$1"
}

get_edit_center() {
  python3 "$HELPER" "$UI_XML" class android.widget.EditText
}

get_action_state() {
  python3 "$HELPER" "$UI_XML" dump_action_state
}

wait_for_action_enabled() {
  local desired="$1"
  local timeout="${2:-60}"
  local start=$(date +%s)

  while true; do
    dump_ui
    local state
    state=$(get_action_state)
    echo "action_state: $state" >&2
    if echo "$state" | grep -q "enabled=$desired"; then
      return 0
    fi
    if [ $(( $(date +%s) - start )) -ge "$timeout" ]; then
      echo "Timed out waiting for action enabled=$desired" >&2
      return 1
    fi
    sleep 1
  done
}

input_message() {
  local text="$1"
  dump_ui
  read -r ex ey <<<"$(get_edit_center)"
  adb -s "$DEVICE" shell input tap "$ex" "$ey"
  sleep 1
  adb -s "$DEVICE" shell input text "$text"
  sleep 1
  dump_ui
  echo "after_input_action: $(get_action_state)" >&2
}

send_message_and_wait_finish() {
  local text="$1"
  input_message "$text"
  dump_ui
  read -r ax ay _ <<<"$(python3 "$HELPER" "$UI_XML" bottom_action)"
  adb -s "$DEVICE" shell input tap "$ax" "$ay"
  sleep 1
  wait_for_action_enabled true 30
  wait_for_action_enabled false 120
  dump_ui
  if ! rg -q "$text" "$UI_XML"; then
    echo "Expected to find sent text '$text' in UI dump." >&2
    return 1
  fi
}

adb -s "$DEVICE" logcat -c
adb -s "$DEVICE" shell am force-stop com.example.aura_app
adb -s "$DEVICE" shell am start -n com.example.aura_app/.MainActivity >/dev/null

wait_for_desc 新建会话 120
read -r nx ny <<<"$(get_desc_center 新建会话)"
adb -s "$DEVICE" shell input tap "$nx" "$ny"

wait_for_desc 结城明日奈 60
wait_for_desc Gemma 60
wait_for_desc AURA 60

send_message_and_wait_finish hello
send_message_and_wait_finish second

input_message stoptest
dump_ui
read -r ax ay _ <<<"$(python3 "$HELPER" "$UI_XML" bottom_action)"
adb -s "$DEVICE" shell input tap "$ax" "$ay"
sleep 1
wait_for_action_enabled true 30
adb -s "$DEVICE" shell input tap "$ax" "$ay"
sleep 1
wait_for_action_enabled false 30

send_message_and_wait_finish afterstop

adb -s "$DEVICE" shell input keyevent 4
wait_for_desc 清空历史 60
read -r cx cy <<<"$(get_desc_center 清空历史)"
adb -s "$DEVICE" shell input tap "$cx" "$cy"
sleep 2
read -r nx ny <<<"$(get_desc_center 新建会话)"
adb -s "$DEVICE" shell input tap "$nx" "$ny"
wait_for_desc AURA 60

dump_ui
if rg -q "hello|second|afterstop|stoptest" "$UI_XML"; then
  echo "History was expected to be cleared, but prior user text is still visible." >&2
  exit 1
fi

adb -s "$DEVICE" exec-out screencap -p > /tmp/aura_manual_final.png
adb -s "$DEVICE" logcat -d -v time | rg \
  "AURA_GENERATION_CANCELLED|AURA_GENERATION_TIMEOUT|TEXT_INFERENCE_FAILED|ENGINE_LOAD_FAILED|Unhandled Exception|dart_vm_initializer|session already exists|failed_precondition|only one session is supported" \
  || true

echo "MANUAL_DEVICE_FLOW_OK"
echo "/tmp/aura_manual_final.png"
