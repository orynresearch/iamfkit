#!/usr/bin/env bash
# build_wasm.sh — Compile libiamfkit to WebAssembly using Emscripten (emcc)
#
# Rewritten: the previous version handed emcc only iamfkit_emscripten.c
# and iamfkit.c directly, never compiling or linking any of libiamf's own
# decoder source, oar, Opus, or FLAC — producing a WASM build with every
# IAMF_decoder_* symbol permanently undefined at link time. This version
# instead builds the *same* code/CMakeLists.txt every other platform
# builds from, routed through emcmake so the whole dependency chain
# (including the ExternalProject_Add-driven Opus/FLAC sub-builds) gets
# cross-compiled for wasm32 — matching this project's "build once, same
# source everywhere" approach instead of a separate, hand-maintained file
# list that can silently drift out of sync (as it just did).
#
# iamfkit.c itself does NOT need to be listed separately here — it's
# already picked up by code/CMakeLists.txt's own `file(GLOB_RECURSE
# sources ... src/*.c ...)` and ends up inside the resulting libiamf.a
# automatically, same as on every other platform.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PKG_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
CODE_SRC="$(cd "$PKG_ROOT/../code" && pwd)"

echo "==> Building WebAssembly module using Emscripten (emcc)"

if ! command -v emcc &> /dev/null; then
    echo "⚠️  emcc (Emscripten) not found in PATH."
    echo "   To compile WebAssembly locally, install emsdk:"
    echo "     git clone https://github.com/emscripten-core/emsdk.git"
    echo "     ./emsdk install latest && ./emsdk activate latest && source ./emsdk_env.sh"
    exit 0
fi

if ! command -v emcmake &> /dev/null; then
    echo "ERROR: emcmake not found (should ship alongside emcc from the same emsdk)."
    exit 1
fi

BUILD_DIR="$SCRIPT_DIR/build_wasm"
rm -rf "$BUILD_DIR"

echo "==> Configuring libiamf (+ oar, Opus, FLAC) for wasm32 via emcmake"
emcmake cmake -S "$CODE_SRC" -B "$BUILD_DIR" \
  -DCMAKE_BUILD_TYPE=Release \
  -DIAMF_BUILD_SHARED_LIB=OFF \
  -DENABLE_BUILD_CODECS=ON \
  -DIAMF_ENABLE_BINAURALIZER=ON \
  -DIAMF_TEST_TOOL=OFF \
  -DBUILD_TESTING=OFF \
  -DEIGEN_BUILD_TESTING=OFF

echo "==> Building static libiamf.a (+ deps) and iamfkit_wasm for wasm32"
cmake --build "$BUILD_DIR" --target iamfkit_wasm --config Release -j"$(nproc 2>/dev/null || sysctl -n hw.logicalcpu 2>/dev/null || echo 4)"

echo "==> Copying WebAssembly artifacts to $SCRIPT_DIR"
if [ -f "$BUILD_DIR/iamfkit_wasm.js" ]; then
  cp "$BUILD_DIR/iamfkit_wasm.js" "$SCRIPT_DIR/iamfkit_wasm.js"
  cp "$BUILD_DIR/iamfkit_wasm.wasm" "$SCRIPT_DIR/iamfkit_wasm.wasm"
else
  find "$BUILD_DIR" -name "iamfkit_wasm.js" -exec cp {} "$SCRIPT_DIR/iamfkit_wasm.js" \;
  find "$BUILD_DIR" -name "iamfkit_wasm.wasm" -exec cp {} "$SCRIPT_DIR/iamfkit_wasm.wasm" \;
fi

echo "✓ WebAssembly compilation complete: $SCRIPT_DIR/iamfkit_wasm.wasm"