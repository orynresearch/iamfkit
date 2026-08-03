#!/bin/bash
set -e

# Base directories
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CODE_DIR="$SCRIPT_DIR"

cd "$CODE_DIR"

echo "=== Building iOS Device target (arm64) ==="
mkdir -p build_ios_device
cd build_ios_device
cmake -DCMAKE_SYSTEM_NAME=iOS \
      -DCMAKE_OSX_SYSROOT=iphoneos \
      -DCMAKE_OSX_ARCHITECTURES=arm64 \
      -DIAMF_BUILD_SHARED_LIB=OFF \
      -DENABLE_BUILD_CODECS=ON \
      -DCMAKE_BUILD_TYPE=Release \
      ..
cmake --build . --config Release -j$(sysctl -n hw.ncpu)
cd ..

echo "=== Building iOS Simulator target (arm64) ==="
mkdir -p build_ios_sim
cd build_ios_sim
cmake -DCMAKE_SYSTEM_NAME=iOS \
      -DCMAKE_OSX_SYSROOT=iphonesimulator \
      -DCMAKE_OSX_ARCHITECTURES=arm64 \
      -DIAMF_BUILD_SHARED_LIB=OFF \
      -DENABLE_BUILD_CODECS=ON \
      -DCMAKE_BUILD_TYPE=Release \
      ..
cmake --build . --config Release -j$(sysctl -n hw.ncpu)
cd ..

echo "=== Merging static libraries ==="
# Find all built static libraries excluding tests
LIBS_DEV=$(find build_ios_device -name "*.a" -not -name "*gtest*" -not -name "*gmock*" -not -name "*test_util*" -not -path "*/googletest-build/*" -not -path "*/googletest-src/*")
LIBS_SIM=$(find build_ios_sim -name "*.a" -not -name "*gtest*" -not -name "*gmock*" -not -name "*test_util*" -not -path "*/googletest-build/*" -not -path "*/googletest-src/*")

mkdir -p device_out simulator_out

echo "Merging device libs..."
libtool -static -o device_out/libiamf.a $LIBS_DEV

echo "Merging simulator libs..."
libtool -static -o simulator_out/libiamf.a $LIBS_SIM

echo "=== Packaging as XCFramework ==="
rm -rf iamf.xcframework

# Create a temporary headers directory to avoid copying private headers
rm -rf tmp_headers
mkdir -p tmp_headers
cp include/*.h tmp_headers/

xcodebuild -create-xcframework \
  -library device_out/libiamf.a \
  -headers tmp_headers \
  -library simulator_out/libiamf.a \
  -headers tmp_headers \
  -output iamf.xcframework

rm -rf tmp_headers
rm -rf device_out simulator_out

echo "=== XCFramework successfully built at $CODE_DIR/iamf.xcframework ==="
