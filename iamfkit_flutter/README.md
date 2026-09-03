# iamfkit

[![pub package](https://img.shields.io/pub/v/iamfkit.svg)](https://pub.dev/packages/iamfkit)

A Flutter FFI plugin for decoding **IAMF (Immersive Audio Model and Formats)** / **Eclipsa Audio** files,
powered by the [AOMedia libiamf](https://github.com/AOMediaCodec/libiamf) library.

## Platform Support

| Platform | Support |
|----------|---------|
| iOS      | ✅ (14.0+) |
| Android  | ✅ (API 21+) |
| macOS    | ✅ (12.0+) |
| Linux    | ✅ (x86_64) |
| Windows  | ✅ (x64) |

## License

**Free for non-commercial use.** Commercial use requires a separate license — see [LICENSE](LICENSE).

---

## What is IAMF?

IAMF (Immersive Audio Model and Formats) is an open standard from the
[Alliance for Open Media](https://aomedia.org/) for encoding and delivering
spatial / immersive audio. Files use the `.iamf` extension.

---

## Installation

```yaml
dependencies:
  iamfkit: ^0.1.0
```

## Usage

```dart
import 'dart:ffi';
import 'dart:io';
import 'package:ffi/ffi.dart';
import 'package:iamfkit/eclipsa_iamf_decoder.dart';

void decodeIamfFile(String filePath) {
  // Open the decoder
  final decoder = bindings.IAMF_decoder_open();
  if (decoder == nullptr) throw Exception('Failed to open decoder');

  // Read the file into native memory
  final bytes = File(filePath).readAsBytesSync();
  final buffer = malloc<Uint8>(bytes.length);
  buffer.asTypedList(bytes.length).setAll(0, bytes);

  // Configure by consuming header packets
  final rsize = malloc<Uint32>();
  int offset = 0;
  while (offset < bytes.length) {
    rsize.value = 0;
    final ret = bindings.IAMF_decoder_configure(
      decoder,
      buffer.elementAt(offset),
      bytes.length - offset,
      rsize,
    );
    if (rsize.value == 0) break;
    offset += rsize.value;
    if (ret == 0) break; // configured
  }

  // Decode frames
  const channels = 2;
  final pcm = malloc<Int16>(4096 * channels);
  while (offset < bytes.length) {
    rsize.value = 0;
    final frames = bindings.IAMF_decoder_decode(
      decoder,
      buffer.elementAt(offset),
      bytes.length - offset,
      rsize,
      pcm.cast<Void>(),
    );
    if (rsize.value == 0 && frames <= 0) break;
    offset += rsize.value;
    // Use pcm.asTypedList(frames * channels) for playback...
  }

  // Clean up
  bindings.IAMF_decoder_close(decoder);
  malloc.free(buffer);
  malloc.free(rsize);
  malloc.free(pcm);
}
```

See the [`example/`](example/) folder for a complete working app using
[`flutter_pcm_sound`](https://pub.dev/packages/flutter_pcm_sound) for real-time playback.

---

## Rebuilding Native Libraries

Pre-built binaries for all platforms are included. To rebuild from the libiamf source:

| Platform | Command |
|----------|---------|
| iOS      | `bash scripts/build_ios.sh` |
| macOS    | `bash scripts/build_macos.sh` |
| Android  | `bash scripts/build_android.sh` (requires Android NDK) |
| Linux    | `bash scripts/build_linux.sh` |
| Windows  | `scripts\build_windows.bat` (requires Visual Studio) |

---

## API Reference

The plugin exposes the full libiamf C API via generated Dart FFI bindings.
Key entry points:

| Function | Description |
|----------|-------------|
| `IAMF_decoder_open()` | Create a new decoder instance |
| `IAMF_decoder_output_layout_set_sound_system(decoder, soundSystem)` | Set output channel layout |
| `IAMF_decoder_set_bit_depth(decoder, bitDepth)` | Set output bit depth (16 or 32) |
| `IAMF_decoder_configure(decoder, data, size, rsize)` | Feed header data until configured |
| `IAMF_decoder_decode(decoder, data, size, rsize, pcm)` | Decode one access unit → PCM |
| `IAMF_decoder_get_stream_info(decoder)` | Query sample rate, channels |
| `IAMF_decoder_close(decoder)` | Free all native resources |

See [`IAMF_decoder.h`](https://github.com/AOMediaCodec/libiamf/blob/main/code/include/IAMF_decoder.h)
for the full C API documentation.

---

## Acknowledgements

- [AOMedia libiamf](https://github.com/AOMediaCodec/libiamf) — BSD 3-Clause
- [libopus](https://opus-codec.org/) — BSD 3-Clause
- [libFLAC](https://xiph.org/flac/) — BSD 3-Clause
- [libfdk-aac](https://github.com/mstorsjo/fdk-aac) — Fraunhofer FDK AAC License
