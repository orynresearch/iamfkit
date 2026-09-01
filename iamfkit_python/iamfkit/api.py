import os
import wave
from typing import Union, Tuple
import numpy as np

from .decoder import IamfDecoder
from .enums import SoundSystem, OutputFormat, parse_sound_system


def decode_file(
    file_path: str,
    output_format: Union[OutputFormat, str] = OutputFormat.FLOAT32,
    layout: Union[SoundSystem, str, int] = "binaural",
) -> Tuple[np.ndarray, int, int]:
    """
    Decode an entire IAMF audio file into a NumPy array.

    Args:
        file_path: Path to the .iamf file.
        output_format: Output dtype ('int16', 'int32', or 'float32').
        layout: Sound system layout alias ('binaural', 'stereo', '5.1', '7.1.4', etc.)
                or SoundSystem enum.

    Returns:
        Tuple[np.ndarray, int, int]: (pcm_data, sample_rate, num_channels)
            pcm_data shape: (total_samples, channels)
    """
    if not os.path.exists(file_path):
        raise FileNotFoundError(f"IAMF file not found: {file_path}")

    sound_system = parse_sound_system(layout)

    with open(file_path, "rb") as f:
        file_bytes = f.read()

    chunks = []
    sample_rate = 48000

    with IamfDecoder(output_format=output_format, sound_system=sound_system) as decoder:
        offset = 0
        total_len = len(file_bytes)

        # Header configure phase
        while offset < total_len:
            consumed, is_configured = decoder.configure(file_bytes[offset:])
            if consumed == 0:
                break
            offset += consumed
            if is_configured:
                sample_rate = decoder.get_sample_rate()
                break

        # Frame decode phase
        while offset < total_len:
            pcm, consumed = decoder.decode(file_bytes[offset:])
            if pcm.shape[0] > 0:
                chunks.append(pcm)
            if consumed == 0 and pcm.shape[0] == 0:
                break
            offset += consumed

        num_channels = decoder.get_num_channels()

    if not chunks:
        dtype = np.float32 if output_format == OutputFormat.FLOAT32 else (
            np.int16 if output_format == OutputFormat.INT16 else np.int32
        )
        return np.empty((0, num_channels), dtype=dtype), sample_rate, num_channels

    full_pcm = np.vstack(chunks)
    return full_pcm, sample_rate, num_channels


def decode_to_wav(
    input_path: str,
    output_wav_path: str,
    layout: Union[SoundSystem, str, int] = "binaural",
) -> str:
    """
    Decode an IAMF file and save it as a standard WAV file.

    Args:
        input_path: Path to .iamf file.
        output_wav_path: Path for generated .wav output.
        layout: Output speaker layout or rendering mode ('binaural', 'stereo', '5.1', '7.1.4', etc.).

    Returns:
        str: Absolute path to the generated WAV file.
    """
    pcm, sr, channels = decode_file(
        input_path,
        output_format=OutputFormat.INT16,
        layout=layout,
    )

    os.makedirs(os.path.dirname(os.path.abspath(output_wav_path)), exist_ok=True)

    with wave.open(output_wav_path, "wb") as wf:
        wf.setnchannels(channels)
        wf.setsampwidth(2)  # int16 = 2 bytes
        wf.setframerate(sr)
        wf.writeframes(pcm.tobytes())

    return os.path.abspath(output_wav_path)
