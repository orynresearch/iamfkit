#!/usr/bin/env bash
# build_android.sh — builds libiamf .so for Android ABIs using the NDK
#
# Usage:
#   ./scripts/build_android.sh                 # local: expects ../code to exist
#   LIBIAMF_SRC=/path/to/libiamf/code ./...    # explicit path (used by CI)
# Requires: Android NDK (set ANDROID_NDK_HOME)

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

OUT_DIR="$REPO_ROOT/android/src/main/jniLibs"

NDK="${ANDROID_NDK_HOME:-${ANDROID_HOME:-$HOME/Library/Android/sdk}/ndk-bundle}"
if [ ! -d "$NDK" ]; then
  NDK=$(ls -d "${ANDROID_HOME:-$HOME/Library/Android/sdk}/ndk/"* 2>/dev/null | sort -V | tail -1)
fi
if [ ! -d "$NDK" ]; then
  echo "ERROR: Android NDK not found. Set ANDROID_NDK_HOME."
  exit 1
fi
echo "==> Using NDK: $NDK"

TOOLCHAIN="$NDK/build/cmake/android.toolchain.cmake"
API_LEVEL=24

build_abi() {
  local ABI=$1
  local BUILD_DIR="$LIBIAMF_SRC/build_android_${ABI//-/_}"
  rm -rf "$BUILD_DIR" && mkdir -p "$BUILD_DIR"
  cmake -S "$LIBIAMF_SRC" -B "$BUILD_DIR" \
    -DCMAKE_TOOLCHAIN_FILE="$TOOLCHAIN" \
    -DANDROID_ABI="$ABI" \
    -DANDROID_PLATFORM="android-$API_LEVEL" \
    -DCMAKE_BUILD_TYPE=Release \
    -DIAMF_BUILD_SHARED_LIB=ON \
    -DENABLE_BUILD_CODECS=ON \
    -DIAMF_ENABLE_BINAURALIZER=ON \
    -DIAMF_TEST_TOOL=OFF \
    -DCMAKE_POLICY_DEFAULT_CMP0057=NEW \
    -DCMAKE_C_FLAGS="-D_GNU_SOURCE" \
    -DCMAKE_CXX_FLAGS="-D_GNU_SOURCE" \
    -DBUILD_TESTING=OFF \
    -DEIGEN_BUILD_TESTING=OFF
  cmake --build "$BUILD_DIR" --config Release -j"$(sysctl -n hw.logicalcpu 2>/dev/null || nproc)"
  local DEST="$OUT_DIR/$ABI"
  mkdir -p "$DEST"
  cp "$BUILD_DIR/libiamf.so" "$DEST/libiamf.so"
  echo "  ✓ $ABI → $DEST/libiamf.so"
}

echo "==> Building libiamf for Android ABIs"
build_abi arm64-v8a
build_abi armeabi-v7a
build_abi x86_64

echo "✓ Android JNI libs written to $OUT_DIR"
