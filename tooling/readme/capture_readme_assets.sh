#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
RAW_DIR="$ROOT_DIR/docs/readme/raw"
mkdir -p "$RAW_DIR"

export DEVELOPER_DIR="${DEVELOPER_DIR:-/Applications/Xcode.app/Contents/Developer}"

if [[ ! -d "$DEVELOPER_DIR" ]]; then
  echo "Xcode developer directory not found: $DEVELOPER_DIR" >&2
  exit 1
fi

choose_device() {
  if [[ -n "${SIMULATOR_UDID:-}" ]]; then
    echo "$SIMULATOR_UDID"
    return
  fi

  local booted
  booted="$(
    xcrun simctl list devices booted |
      rg 'iPhone .*\(([A-F0-9-]{36})\)' -or '$1' -m 1 || true
  )"
  if [[ -n "$booted" ]]; then
    echo "$booted"
    return
  fi

  xcrun simctl list devices available |
    rg 'iPhone .*\(([A-F0-9-]{36})\)' -or '$1' -m 1
}

DEVICE_ID="$(choose_device)"
if [[ -z "$DEVICE_ID" ]]; then
  echo "No iPhone simulator available." >&2
  exit 1
fi

open -a Simulator --args -CurrentDeviceUDID "$DEVICE_ID"
xcrun simctl boot "$DEVICE_ID" >/dev/null 2>&1 || true
xcrun simctl bootstatus "$DEVICE_ID" -b

xcrun simctl uninstall "$DEVICE_ID" app.aura.story >/dev/null 2>&1 || true
rm -f \
  "$RAW_DIR/model-setup-raw.png" \
  "$RAW_DIR/story-library-raw.png" \
  "$RAW_DIR/chat-scene-raw.png" \
  "$RAW_DIR/import-flow-raw.png" \
  "$RAW_DIR/quick-start.mov"

xcrun simctl io "$DEVICE_ID" recordVideo --codec=h264 "$RAW_DIR/quick-start.mov" \
  >/dev/null 2>&1 &
RECORD_PID=$!

cleanup() {
  if kill -0 "$RECORD_PID" >/dev/null 2>&1; then
    kill -INT "$RECORD_PID" >/dev/null 2>&1 || true
    wait "$RECORD_PID" >/dev/null 2>&1 || true
  fi
}
trap cleanup EXIT

cd "$ROOT_DIR"
flutter drive \
  --driver=test_driver/readme_capture.dart \
  --target=integration_test/readme_capture_test.dart \
  -d "$DEVICE_ID" \
  --dart-define=AURA_USE_FAKE_GATEWAY=true

cleanup
trap - EXIT

python3 "$ROOT_DIR/tooling/readme/build_readme_media.py"
