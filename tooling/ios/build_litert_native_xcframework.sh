#!/bin/zsh
set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
REPO_ROOT=$(cd "$SCRIPT_DIR/../.." && pwd)
OVERLAY_DIR="$REPO_ROOT/tooling/ios/litert_native"
DEFAULT_LITERT_REPO="/tmp/aura_research/LiteRT-LM"
LITERT_REPO="${LITERT_REPO:-$DEFAULT_LITERT_REPO}"
TARGET_DIR="$LITERT_REPO/aura_ios_native"
OUTPUT_ZIP="$LITERT_REPO/bazel-bin/aura_ios_native/AuraLiteRTNative_xcframework.xcframework.zip"
DEST_DIR="$REPO_ROOT/ios/Frameworks"
DEST_XCFRAMEWORK="$DEST_DIR/AuraLiteRTNative.xcframework"

export DEVELOPER_DIR="${DEVELOPER_DIR:-/Applications/Xcode.app/Contents/Developer}"

if [[ ! -d "$LITERT_REPO/.git" ]]; then
  mkdir -p "$(dirname "$LITERT_REPO")"
  git clone --depth 1 https://github.com/google-ai-edge/LiteRT-LM.git "$LITERT_REPO"
fi

ENGINE_IMPL_FILE="$LITERT_REPO/runtime/core/engine_impl.cc"
ENGINE_ADVANCED_IMPL_FILE="$LITERT_REPO/runtime/core/engine_advanced_impl.cc"

if ! rg -q "AuraLiteRTNativeForceLinkEngineImpl" "$ENGINE_IMPL_FILE"; then
  cat <<'EOF' >> "$ENGINE_IMPL_FILE"

extern "C" void AuraLiteRTNativeForceLinkEngineImpl(void) {}
EOF
fi

if ! rg -q "AuraLiteRTNativeForceLinkEngineAdvancedImpl" "$ENGINE_ADVANCED_IMPL_FILE"; then
  cat <<'EOF' >> "$ENGINE_ADVANCED_IMPL_FILE"

extern "C" void AuraLiteRTNativeForceLinkEngineAdvancedImpl(void) {}
EOF
fi

rm -rf "$TARGET_DIR"
mkdir -p "$TARGET_DIR"
cp "$OVERLAY_DIR/BUILD.bazel" "$TARGET_DIR/BUILD"
cp "$OVERLAY_DIR/AuraLiteRTNative.h" "$TARGET_DIR/AuraLiteRTNative.h"
cp "$OVERLAY_DIR/AuraLiteRTNative.mm" "$TARGET_DIR/AuraLiteRTNative.mm"

cd "$LITERT_REPO"
bazel build \
  --config=ios \
  --define=LITERT_LM_FST_CONSTRAINTS_DISABLED=1 \
  --build_tag_filters=-requires-mac-inputs:hard,-no_mac \
  //aura_ios_native:AuraLiteRTNative_xcframework

rm -rf "$DEST_XCFRAMEWORK"
mkdir -p "$DEST_DIR"
unzip -oq "$OUTPUT_ZIP" -d "$DEST_DIR"

echo "Built $DEST_XCFRAMEWORK"
