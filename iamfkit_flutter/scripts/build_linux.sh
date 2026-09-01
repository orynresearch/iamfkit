#!/usr/bin/env bash
# build_linux.sh — builds libiamf.so for Linux x86_64
#
# Usage:
#   ./scripts/build_linux.sh                   # local: expects ../code to exist
#   LIBIAMF_SRC=/path/to/libiamf/code ./...    # explicit path (used by CI)
# Requires: cmake, gcc, make

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

OUT_DIR="$REPO_ROOT/linux"
BUILD_DIR="$LIBIAMF_SRC/build_linux"

echo "==> Building libiamf for Linux x86_64"
rm -rf "$BUILD_DIR" && mkdir -p "$BUILD_DIR"
cmake -S "$LIBIAMF_SRC" -B "$BUILD_DIR" \
  -DCMAKE_BUILD_TYPE=Release \
  -DIAMF_BUILD_SHARED_LIB=ON \
  -DENABLE_BUILD_CODECS=ON \
  -DIAMF_ENABLE_BINAURALIZER=ON \
  -DIAMF_TEST_TOOL=OFF \
  -DBUILD_TESTING=OFF \
  -DEIGEN_BUILD_TESTING=OFF
cmake --build "$BUILD_DIR" --config Release -j"$(nproc)"
cp "$BUILD_DIR/libiamf.so" "$OUT_DIR/libiamf.so"
echo "✓ Linux shared library at: $OUT_DIR/libiamf.so"
