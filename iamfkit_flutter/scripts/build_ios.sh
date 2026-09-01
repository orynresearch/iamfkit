#!/usr/bin/env bash
# build_ios.sh — builds libiamf as an iOS XCFramework (device + simulator)
#
# Usage:
#   ./scripts/build_ios.sh                     # local: expects ../code to exist
#   LIBIAMF_SRC=/path/to/libiamf/code ./...    # explicit path (used by CI)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Allow CI to pass in the libiamf source path explicitly
LIBIAMF_SRC="${LIBIAMF_SRC:-$(cd "$REPO_ROOT/../code" 2>/dev/null && pwd || echo "")}"
if [ -z "$LIBIAMF_SRC" ] || [ ! -d "$LIBIAMF_SRC" ]; then
  echo "ERROR: libiamf source not found."
  echo "Set LIBIAMF_SRC=/path/to/libiamf/code or run from inside the monorepo."
  exit 1
fi
echo "==> Using libiamf source: $LIBIAMF_SRC"

OUT_IOS="$REPO_ROOT/ios"

build_ios() {
  local SDK=$1 ARCH=$2 SUFFIX=$3
  local BUILD_DIR="$LIBIAMF_SRC/build_ios_${SUFFIX}"
  rm -rf "$BUILD_DIR" && mkdir -p "$BUILD_DIR"
  cmake -S "$LIBIAMF_SRC" -B "$BUILD_DIR" \
    -DCMAKE_BUILD_TYPE=Release \
    -DIAMF_BUILD_SHARED_LIB=OFF \
    -DENABLE_BUILD_CODECS=ON \
    -DIAMF_ENABLE_BINAURALIZER=ON \
    -DIAMF_TEST_TOOL=OFF \
    -DCMAKE_SYSTEM_NAME=iOS \
    -DCMAKE_OSX_SYSROOT="$(xcrun --sdk $SDK --show-sdk-path)" \
    -DCMAKE_OSX_ARCHITECTURES="$ARCH" \
    -DCMAKE_OSX_DEPLOYMENT_TARGET="14.0" \
    -DBUILD_TESTING=OFF \
    -DEIGEN_BUILD_TESTING=OFF
  cmake --build "$BUILD_DIR" --config Release -j"$(sysctl -n hw.logicalcpu)"
}

echo "==> Building iOS device (arm64)"
build_ios iphoneos arm64 device
DEVICE_BUILD="$LIBIAMF_SRC/build_ios_device"

echo "==> Building iOS simulator (arm64 + x86_64)"
build_ios iphonesimulator arm64 sim_arm64
SIM_ARM="$LIBIAMF_SRC/build_ios_sim_arm64"

build_ios iphonesimulator x86_64 sim_x86_64
SIM_X86="$LIBIAMF_SRC/build_ios_sim_x86_64"

# Merge simulator slices
MERGED_SIM="$LIBIAMF_SRC/build_ios_sim_universal/libiamf.a"
mkdir -p "$(dirname "$MERGED_SIM")"
lipo -create "$SIM_ARM/libiamf.a" "$SIM_X86/libiamf.a" -output "$MERGED_SIM"

echo "==> Creating iOS XCFramework"
XCFW="$OUT_IOS/iamf.xcframework"
rm -rf "$XCFW"
xcodebuild -create-xcframework \
  -library "$DEVICE_BUILD/libiamf.a" \
  -headers "$LIBIAMF_SRC/include" \
  -library "$MERGED_SIM" \
  -headers "$LIBIAMF_SRC/include" \
  -output "$XCFW"

echo "✓ iOS XCFramework at: $XCFW"
