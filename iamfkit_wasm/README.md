# iamfkit-web (WebAssembly & Web Audio API)

[![npm version](https://img.shields.io/npm/v/iamfkit-web.svg)](https://www.npmjs.com/package/iamfkit-web)

WebAssembly SDK and Web Audio API decoder for playing **IAMF (Immersive Audio Model and Formats)** files directly in web browsers.

Powered by the [AOMedia libiamf](https://github.com/AOMediaCodec/libiamf) C library compiled to WebAssembly via Emscripten.

---

## Features

- 🌐 **Browser Native**: Run 3D spatial audio decoding inside any modern web browser (Chrome, Safari, Firefox, Edge).
- 🎧 **3D Binaural Headphones**: Render immersive 3D binaural spatial audio for web music players, web games, or streaming apps.
- 🎛️ **Web Audio API**: `decodeToAudioBuffer()` converts `.iamf` files directly into native `AudioBuffer` objects ready for instant playback with `AudioBufferSourceNode`.

---

## Quickstart

### 1. Install via NPM

```bash
npm install iamfkit-web
```

### 2. Decode & Play via Web Audio API

```typescript
import { decodeToAudioBuffer } from 'iamfkit-web';

const audioContext = new AudioContext();

async function playIamf(fileArrayBuffer: ArrayBuffer) {
  // Decode IAMF bitstream directly to Web Audio API AudioBuffer
  const audioBuffer = await decodeToAudioBuffer(fileArrayBuffer, audioContext, {
    layout: 'binaural', // 'binaural', 'stereo', '5.1', '7.1.4'
  });

  // Play audio
  const source = audioContext.createBufferSource();
  source.buffer = audioBuffer;
  source.connect(audioContext.destination);
  source.start();
}
```

---

## Interactive Demo

Open `examples/index.html` in your browser to view the interactive web audio player demo with real-time spectrum visualization!

---

## License

Source-Available License. See [LICENSE](LICENSE) for terms.
