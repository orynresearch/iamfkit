# iamfkit (Python)

[![PyPI version](https://img.shields.io/pypi/v/iamfkit.svg)](https://pypi.org/project/iamfkit/)

Python integration kit for decoding **IAMF (Immersive Audio Model and Formats)** files directly into **NumPy arrays** and **WAV files**.

Powered by the [AOMedia libiamf](https://github.com/AOMediaCodec/libiamf) C library.

---

## Features

- 🐍 **Pythonic `IamfDecoder` API**: Clean context-manager support (`with IamfDecoder() as dec:`).
- 🔢 **Flexible NumPy Dtypes**: Decode to `float32` (normalized `[-1.0, 1.0]`), `int16`, or `int32`.
- 🎧 **3D Binaural & Multichannel Support**: Easily render for Headphones (Binaural 3D), Stereo, 5.1, or 7.1.4.
- 🎛️ **Loudness Normalization & Head Tracking**: Support for EBU R128 loudness target and quaternion-based head tracking.
- 🛠️ **CLI Tool (`iamfkit`)**: Quick file conversion and inspection right from your shell.

---

## Installation

```bash
pip install iamfkit
```

---

## Quickstart

### 1. Decode to NumPy array

```python
import iamfkit

# Decode directly into a NumPy float32 array
pcm, sample_rate, channels = iamfkit.decode_file(
    "audio.iamf",
    output_format="float32",  # 'float32', 'int16', or 'int32'
    sound_system=iamfkit.SoundSystem.SOUND_SYSTEM_BINAURAL, # 3D Binaural rendering
)

print(f"Decoded shape: {pcm.shape}")  # (samples, channels)
print(f"Sample rate: {sample_rate} Hz, Channels: {channels}")
```

### 2. Decode directly to a WAV file

```python
import iamfkit

# Convert IAMF to WAV
iamfkit.decode_to_wav("audio.iamf", "output.wav")
```

### 3. Stream / Low-level Decoder API

```python
from iamfkit import IamfDecoder, SoundSystem, OutputFormat

with IamfDecoder(
    output_format=OutputFormat.FLOAT32,
    sound_system=SoundSystem.SOUND_SYSTEM_STEREO
) as decoder:
    
    # Optional: Configure head rotation quaternion (w, x, y, z) for 3D binaural
    decoder.set_head_rotation(1.0, 0.0, 0.0, 0.0)

    # Configure header
    consumed = decoder.configure(header_bytes)
    
    # Decode chunk
    pcm_chunk, bytes_used = decoder.decode(frame_bytes)
```

---

## Command Line Interface (CLI)

```bash
# Convert IAMF file to WAV
iamfkit input.iamf output.wav --layout binaural

# Decode to int16 PCM
iamfkit input.iamf output.wav --format int16 --layout stereo
```

---

## License

BSD-3-Clause License. See [LICENSE](LICENSE) for details.
