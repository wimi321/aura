#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

export DEVELOPER_DIR="${DEVELOPER_DIR:-/Applications/Xcode.app/Contents/Developer}"
FRAMEWORK_DIR="$ROOT_DIR/ios/Frameworks/AuraLiteRTNative.xcframework"

if [[ ! -d "$DEVELOPER_DIR" ]]; then
  echo "Xcode developer directory not found: $DEVELOPER_DIR" >&2
  echo "Set DEVELOPER_DIR to your Xcode.app/Contents/Developer path and retry." >&2
  exit 1
fi

if [[ ! -d "$FRAMEWORK_DIR" ]]; then
  if ! command -v bazel >/dev/null 2>&1; then
    echo "Aura iOS runtime is missing: $FRAMEWORK_DIR" >&2
    echo "Install Bazel, then run ./tooling/ios/build_litert_native_xcframework.sh and retry." >&2
    exit 1
  fi

  echo "Aura iOS runtime not found. Building local XCFramework..."
  ./tooling/ios/build_litert_native_xcframework.sh
fi

if flutter build ios --simulator --no-codesign; then
  exit 0
fi

echo "Flutter iOS simulator wrapper failed; retrying with xcodebuild fallback..."
(
  cd ios
  xcodebuild \
    -workspace Runner.xcworkspace \
    -scheme Runner \
    -configuration Debug \
    -sdk iphonesimulator \
    -destination 'generic/platform=iOS Simulator' \
    CODE_SIGNING_ALLOWED=NO \
    CODE_SIGNING_REQUIRED=NO \
    CODE_SIGNING_IDENTITY='' \
    COMPILER_INDEX_STORE_ENABLE=NO \
    build
)
