#!/usr/bin/env bash
# build_wasm.sh — Compile libiamfkit to WebAssembly using Emscripten (emcc)

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

emcc -O3 \
  -I"$CODE_SRC/include" \
  -I"$CODE_SRC/src/iamf_dec" \
  "$SCRIPT_DIR/iamfkit_emscripten.c" \
  "$CODE_SRC/src/iamfkit.c" \
  -s WASM=1 \
  -s EXPORTED_RUNTIME_METHODS='["cwrap", "getValue", "setValue", "_malloc", "_free"]' \
  -s ALLOW_MEMORY_GROWTH=1 \
  -s MODULARIZE=1 \
  -s EXPORT_NAME='IamfKitWasm' \
  -o "$SCRIPT_DIR/iamfkit_wasm.js"

echo "✓ WebAssembly compilation complete: $SCRIPT_DIR/iamfkit_wasm.wasm"
