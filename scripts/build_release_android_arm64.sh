#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

flutter build apk --release --target-platform android-arm64
ls -lh build/app/outputs/flutter-apk/app-release.apk
