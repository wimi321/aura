#!/bin/zsh
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/../.." && pwd)"
DEVELOPER_DIR="${DEVELOPER_DIR:-/Applications/Xcode.app/Contents/Developer}"
APP_BUNDLE_ID="app.aura.story"
APP_PATH="$ROOT_DIR/build/ios/Debug-iphonesimulator/Runner.app"

export DEVELOPER_DIR

SIMULATOR_ID="${1:-}"
if [[ -z "$SIMULATOR_ID" ]]; then
  SIMULATOR_ID="$(xcrun simctl list devices booted | rg -o '[A-F0-9-]{8}-[A-F0-9]{4}-[A-F0-9]{4}-[A-F0-9]{4}-[A-F0-9]{12}' -m 1 || true)"
fi

if [[ -z "$SIMULATOR_ID" ]]; then
  echo "No booted iOS simulator found. Boot one in Simulator.app first." >&2
  exit 1
fi

xcodebuild \
  -workspace "$ROOT_DIR/ios/Runner.xcworkspace" \
  -scheme Runner \
  -configuration Debug \
  -sdk iphonesimulator \
  -destination "id=$SIMULATOR_ID" \
  BUILD_DIR="$ROOT_DIR/build/ios" \
  build

xcrun simctl install "$SIMULATOR_ID" "$APP_PATH"
xcrun simctl terminate "$SIMULATOR_ID" "$APP_BUNDLE_ID" >/dev/null 2>&1 || true
xcrun simctl launch "$SIMULATOR_ID" "$APP_BUNDLE_ID"
