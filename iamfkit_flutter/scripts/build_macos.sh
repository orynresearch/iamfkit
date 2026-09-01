#!/usr/bin/env bash
# build_macos.sh — builds libiamf as a universal macOS XCFramework (arm64 + x86_64)
#
# Usage:
#   ./scripts/build_macos.sh                   # local: expects ../code to exist
#   LIBIAMF_SRC=/path/to/libiamf/code ./...    # explicit path (used by CI)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

LIBIAMF_SRC="${LIBIAMF_SRC:-$(cd "$REPO_ROOT/../code" 2>/dev/null && pwd || echo "")}"
if [ -z "$LIBIAMF_SRC" ] || [ ! -d "$LIBIAMF_SRC" ]; then
  echo "ERROR: libiamf source not found."
  echo "Set LIBIAMF_SRC=/path/to/libiamf/code or run from inside the monorepo."
  exit 1
fi
echo "==> Using libiamf source: $LIBIAMF_SRC"

OUT_DIR="$REPO_ROOT/macos"

build_arch() {
  local ARCH=$1
  local BUILD_DIR="$LIBIAMF_SRC/build_macos_${ARCH}"
  rm -rf "$BUILD_DIR" && mkdir -p "$BUILD_DIR"
  cmake -S "$LIBIAMF_SRC" -B "$BUILD_DIR" \
    -DCMAKE_BUILD_TYPE=Release \
    -DIAMF_BUILD_SHARED_LIB=OFF \
    -DENABLE_BUILD_CODECS=ON \
    -DIAMF_ENABLE_BINAURALIZER=ON \
    -DIAMF_TEST_TOOL=OFF \
    -DCMAKE_OSX_ARCHITECTURES="$ARCH" \
    -DCMAKE_OSX_DEPLOYMENT_TARGET="12.0" \
    -DBUILD_TESTING=OFF \
    -DEIGEN_BUILD_TESTING=OFF
  cmake --build "$BUILD_DIR" --config Release -j"$(sysctl -n hw.logicalcpu)"
}

echo "==> Building macOS arm64"
build_arch arm64
ARM64_BUILD="$LIBIAMF_SRC/build_macos_arm64"

echo "==> Building macOS x86_64"
build_arch x86_64
X86_BUILD="$LIBIAMF_SRC/build_macos_x86_64"

# Merge into a universal static lib
MERGED_DIR="$LIBIAMF_SRC/build_macos_universal"
rm -rf "$MERGED_DIR" && mkdir -p "$MERGED_DIR/lib" "$MERGED_DIR/include"
lipo -create "$ARM64_BUILD/libiamf.a" "$X86_BUILD/libiamf.a" \
  -output "$MERGED_DIR/lib/libiamf.a"
cp "$LIBIAMF_SRC/include/"*.h "$MERGED_DIR/include/"

echo "==> Creating macOS XCFramework"
XCFW="$OUT_DIR/iamf_macos.xcframework"
rm -rf "$XCFW"
xcodebuild -create-xcframework \
  -library "$MERGED_DIR/lib/libiamf.a" \
  -headers "$MERGED_DIR/include" \
  -output "$XCFW"

echo "✓ macOS XCFramework at: $XCFW"
