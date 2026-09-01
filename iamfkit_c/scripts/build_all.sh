#!/usr/bin/env bash
# build_all.sh — Standalone C library builder for libiamfkit
# Builds libiamfkit shared dynamic library and simple_decode example C app.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PKG_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
CODE_SRC="$(cd "$PKG_ROOT/../code" && pwd)"

BUILD_DIR="$PKG_ROOT/build"
rm -rf "$BUILD_DIR" && mkdir -p "$BUILD_DIR"

echo "==> Building standalone libiamfkit C dynamic library"
cmake -S "$CODE_SRC" -B "$BUILD_DIR" \
  -DCMAKE_BUILD_TYPE=Release \
  -DIAMF_BUILD_SHARED_LIB=ON \
  -DENABLE_BUILD_CODECS=ON \
  -DIAMF_ENABLE_BINAURALIZER=ON \
  -DIAMF_TEST_TOOL=OFF \
  -DBUILD_TESTING=OFF \
  -DEIGEN_BUILD_TESTING=OFF

cmake --build "$BUILD_DIR" --config Release -j"$(sysctl -n hw.logicalcpu 2>/dev/null || nproc)"

echo "==> Compiling C example application (simple_decode)"
clang -O3 -I"$PKG_ROOT/include" -L"$BUILD_DIR" \
  "$PKG_ROOT/examples/simple_decode.c" \
  -liamf -Wl,-rpath,"$BUILD_DIR" \
  -o "$BUILD_DIR/simple_decode"

echo "✓ Build complete!"
echo "  - Dynamic library: $BUILD_DIR/libiamf.dylib (or .so / .dll)"
echo "  - C example binary: $BUILD_DIR/simple_decode"
