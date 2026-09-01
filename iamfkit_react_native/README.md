# iamfkit-react-native

[![npm version](https://img.shields.io/npm/v/iamfkit-react-native.svg)](https://www.npmjs.com/package/iamfkit-react-native)

React Native & Expo module for decoding **IAMF (Immersive Audio Model and Formats)** files directly into PCM audio data in iOS & Android applications.

Powered by the [AOMedia libiamf](https://github.com/AOMediaCodec/libiamf) C library via the native `libiamfkit` wrapper.

---

## Features

- ⚛️ **React Native & Expo Support**: Works with standard React Native apps & Expo Development Builds (`npx expo install iamfkit-react-native`).
- 🎧 **3D Binaural & Multichannel**: Render for Binaural Headphones (3D), Stereo, 5.1, or 7.1.4 Dolby Atmos beds.
- ⚡ **Native Performance**: Decodes in background native threads via Objective-C++ / Kotlin & `libiamfkit`.
- 🎚️ **Loudness Normalization**: EBU R128 loudness target normalization support.

---

## Installation

### Expo Project
```bash
npx expo install iamfkit-react-native
```

### Bare React Native Project
```bash
npm install iamfkit-react-native
cd ios && pod install
```

---

## Usage

```typescript
import { IamfDecoder } from 'iamfkit-react-native';

async function decodeAudio() {
  try {
    const result = await IamfDecoder.decodeFile('file:///path/to/audio.iamf', {
      layout: 'binaural', // 'binaural', 'stereo', '5.1', '7.1.4'
      outputFormat: 'float32',
    });

    console.log(`Sample rate: ${result.sampleRate} Hz`);
    console.log(`Channels: ${result.channels}`);
    console.log(`PCM Data (Base64): ${result.pcmBase64.substring(0, 30)}...`);
  } catch (error) {
    console.error('Decoding failed:', error);
  }
}
```

---

## License

Source-Available License. See [LICENSE](LICENSE) for terms.
