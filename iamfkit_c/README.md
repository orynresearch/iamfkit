# iamfkit (Native C Shared Library)

Standalone, zero-dependency C dynamic library (`libiamfkit.dylib`, `libiamfkit.so`, `iamfkit.dll`) for decoding **IAMF (Immersive Audio Model and Formats)** files in any native programming environment (C, C++, Rust, Go, Zig, Swift, C#, embedded).

Powered by the [AOMedia libiamf](https://github.com/AOMediaCodec/libiamf) C library.

---

## Features

- ⚡ **Pure C API**: No language runtimes, no dependencies. High performance & low memory footprint.
- 🎧 **3D Binaural & Multichannel**: Built-in channel-based and scene-based binaural renderer (Headphones 3D), 5.1, 7.1.4 Dolby Atmos beds.
- 🎚️ **Loudness & Limiting**: EBU R128 loudness target normalization and peak limiting.
- 🌐 **Cross-Platform**: Pre-compiled binaries for macOS (arm64/x86_64), Linux (x86_64), Android (arm64/v7a), iOS (XCFramework), and Windows (x64).

---

## Quickstart (C / C++)

### 1. Include Header & Link Library

Add `iamfkit.h` to your project and link `-liamfkit`:

```c
#include <stdio.h>
#include "iamfkit.h"

int main() {
    IamfKitDecoderHandle decoder = iamfkit_decoder_open();
    
    // Set 3D Binaural rendering
    iamfkit_decoder_set_sound_system(decoder, IAMFKIT_SOUND_SYSTEM_BINAURAL);
    iamfkit_decoder_set_bit_depth(decoder, IAMFKIT_BIT_DEPTH_16);

    // Feed header configuration...
    // Decode frames...

    iamfkit_decoder_close(decoder);
    return 0;
}
```

### 2. Build Example C Decoder

```bash
# Run build script
bash scripts/build_all.sh

# Run C example decoder
./build/simple_decode input.iamf output.wav
```

---

## C API Reference (`iamfkit.h`)

| Function | Description |
|----------|-------------|
| `iamfkit_decoder_open()` | Allocate new IAMF decoder instance |
| `iamfkit_decoder_set_sound_system(handle, system)` | Set layout (`IAMFKIT_SOUND_SYSTEM_STEREO`, `IAMFKIT_SOUND_SYSTEM_BINAURAL`, `IAMFKIT_SOUND_SYSTEM_7_1_4`) |
| `iamfkit_decoder_set_bit_depth(handle, depth)` | Set PCM bit depth (`16`, `24`, `32`) |
| `iamfkit_decoder_set_normalization_loudness(handle, lkfs)` | Set EBU R128 target (e.g. `-23.0f`) |
| `iamfkit_decoder_set_head_rotation(handle, w, x, y, z)` | Quaternion head tracking for 3D binaural rendering |
| `iamfkit_decoder_configure(handle, data, size, &consumed, &is_cfg)` | Feed configuration header bytes |
| `iamfkit_decoder_decode(handle, data, size, &consumed, pcm_out)` | Decode chunk to PCM buffer |
| `iamfkit_decoder_get_info(handle, &info)` | Retrieve sample rate, channels, element counts |
| `iamfkit_decoder_close(handle)` | Free decoder instance |

---

## Other Languages

### Rust (`bindgen` / `extern "C"`)
```rust
extern "C" {
    pub fn iamfkit_decoder_open() -> *mut std::ffi::c_void;
    pub fn iamfkit_decoder_close(handle: *mut std::ffi::c_void) -> std::ffi::c_int;
}
```

### Go (`cgo`)
```go
/*
#cgo LDFLAGS: -liamfkit
#include "iamfkit.h"
*/
import "C"
```

### Zig
```zig
const c = @cImport({
    @cInclude("iamfkit.h");
});
```

---

## License

Source-Available License (Free for non-commercial use, commercial license required for commercial products). See [LICENSE](LICENSE).
