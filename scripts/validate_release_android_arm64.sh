#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

VERSION="$(awk '/^version:/ { print $2 }' pubspec.yaml | cut -d+ -f1)"
APK_NAME="aura-${VERSION}-arm64-v8a.apk"

python3 -m py_compile \
  tooling/branding/generate_app_brand_assets.py \
  tooling/branding/apply_generated_story_covers.py \
  tooling/branding/optimize_character_covers.py

(cd packages/aura_core && dart test)
flutter analyze
flutter test
flutter build apk --release --target-platform android-arm64

mkdir -p dist
cp build/app/outputs/flutter-apk/app-release.apk "dist/${APK_NAME}"
shasum -a 256 "dist/${APK_NAME}" | tee "dist/${APK_NAME}.sha256"
ls -lh "dist/${APK_NAME}" "dist/${APK_NAME}.sha256"
