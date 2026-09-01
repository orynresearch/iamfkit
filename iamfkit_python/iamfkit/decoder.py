import ctypes
from typing import Optional, Union, Tuple
import numpy as np

from ._bindings import (
    get_lib,
    IamfKitStreamInfo,
)
from .enums import SoundSystem, SampleBitDepth, OutputFormat, parse_sound_system


class IamfDecoder:
    """
    High-level Pythonic decoder for IAMF / Eclipsa Audio streams.
    Consumes the unified libiamfkit C wrapper API.
    """

    def __init__(
        self,
        output_format: Union[OutputFormat, str] = OutputFormat.FLOAT32,
        sound_system: Union[SoundSystem, str, int] = SoundSystem.SOUND_SYSTEM_STEREO,
        target_loudness_lkfs: Optional[float] = None,
        enable_peak_limiter: bool = True,
    ):
        self._lib = get_lib()
        self._handle = self._lib.iamfkit_decoder_open()
        if not self._handle:
            raise RuntimeError("Failed to allocate iamfkit native decoder handle")

        self.set_output_format(output_format)
        self.set_sound_system(sound_system)

        if target_loudness_lkfs is not None:
            self.set_normalization_loudness(target_loudness_lkfs)

        self.set_peak_limiter_enabled(enable_peak_limiter)
        self._configured = False

    def __enter__(self):
        return self

    def __exit__(self, exc_type, exc_val, exc_tb):
        self.close()

    def close(self):
        """Release native decoder resources."""
        if self._handle:
            self._lib.iamfkit_decoder_close(self._handle)
            self._handle = None

    def set_output_format(self, output_format: Union[OutputFormat, str]):
        """Set the PCM output format ('int16', 'int32', or 'float32')."""
        if isinstance(output_format, str):
            output_format = OutputFormat(output_format.lower())

        self.output_format = output_format

        if output_format == OutputFormat.INT16:
            self.bit_depth = SampleBitDepth.BIT_DEPTH_16
        elif output_format in (OutputFormat.INT32, OutputFormat.FLOAT32):
            self.bit_depth = SampleBitDepth.BIT_DEPTH_32
        else:
            raise ValueError(f"Unsupported output format: {output_format}")

        if self._handle:
            res = self._lib.iamfkit_decoder_set_bit_depth(self._handle, int(self.bit_depth))
            if res != 0:
                raise RuntimeError(f"iamfkit_decoder_set_bit_depth returned error code {res}")

    def set_sound_system(self, sound_system: Union[SoundSystem, str, int]):
        """Set output speaker layout or binaural 3D rendering."""
        self.sound_system = parse_sound_system(sound_system)
        if not self._handle:
            return

        res = self._lib.iamfkit_decoder_set_sound_system(self._handle, int(self.sound_system))
        if res != 0:
            raise RuntimeError(f"Failed to set output sound system: error code {res}")

    def set_normalization_loudness(self, target_lkfs: float):
        """Configure EBU R128 loudness target in dB (LKFS)."""
        res = self._lib.iamfkit_decoder_set_normalization_loudness(self._handle, float(target_lkfs))
        if res != 0:
            raise RuntimeError(f"Failed to set normalization loudness: error {res}")

    def set_peak_limiter_enabled(self, enable: bool):
        """Enable or disable the native peak limiter."""
        res = self._lib.iamfkit_decoder_enable_peak_limiter(self._handle, 1 if enable else 0)
        if res != 0:
            raise RuntimeError(f"Failed to set peak limiter state: error {res}")

    def set_head_rotation(self, w: float, x: float, y: float, z: float):
        """Set head rotation quaternion for binaural 3D audio rendering."""
        res = self._lib.iamfkit_decoder_set_head_rotation(self._handle, float(w), float(x), float(y), float(z))
        if res != 0:
            raise RuntimeError(f"Failed to set head rotation: error {res}")

    def configure(self, buffer: bytes) -> Tuple[int, bool]:
        """
        Configure decoder with initial IAMF header bytes via unified C wrapper.
        """
        if not buffer:
            return 0, self._configured

        c_buf = (ctypes.c_uint8 * len(buffer)).from_buffer_copy(buffer)
        rsize = ctypes.c_uint32(0)
        is_cfg = ctypes.c_int(0)

        res = self._lib.iamfkit_decoder_configure(
            self._handle, c_buf, len(buffer), ctypes.byref(rsize), ctypes.byref(is_cfg)
        )
        configured = bool(is_cfg.value == 1)
        if configured:
            self._configured = True

        return rsize.value, configured

    def get_num_channels(self) -> int:
        """Returns number of audio channels from C stream info or layout default."""
        if self._handle:
            info = IamfKitStreamInfo()
            res = self._lib.iamfkit_decoder_get_info(self._handle, ctypes.byref(info))
            if res == 0 and info.num_channels > 0:
                return info.num_channels

        # Default channel mapping based on sound system
        if self.sound_system == SoundSystem.SOUND_SYSTEM_BINAURAL:
            return 2
        elif self.sound_system in (SoundSystem.SOUND_SYSTEM_STEREO, SoundSystem.SOUND_SYSTEM_J_2_0_0):
            return 2
        elif self.sound_system == SoundSystem.SOUND_SYSTEM_B_0_5_0:
            return 5
        elif self.sound_system == SoundSystem.SOUND_SYSTEM_C_0_7_0:
            return 7
        elif self.sound_system == SoundSystem.SOUND_SYSTEM_D_5_1_2:
            return 8
        elif self.sound_system == SoundSystem.SOUND_SYSTEM_E_5_1_4:
            return 10
        elif self.sound_system == SoundSystem.SOUND_SYSTEM_F_7_1_4:
            return 12
        return 2

    def get_sample_rate(self) -> int:
        """Get stream sampling rate from C stream info."""
        if not self._handle:
            return 48000
        info = IamfKitStreamInfo()
        res = self._lib.iamfkit_decoder_get_info(self._handle, ctypes.byref(info))
        if res == 0 and info.sample_rate > 0:
            return info.sample_rate
        return 48000

    def decode(self, data_chunk: bytes) -> Tuple[np.ndarray, int]:
        """
        Decode a single chunk of IAMF OBUs via the unified C wrapper.
        """
        if not self._handle:
            raise RuntimeError("Decoder is closed")

        channels = self.get_num_channels()
        max_samples_per_frame = 4096

        c_buf = (ctypes.c_uint8 * len(data_chunk)).from_buffer_copy(data_chunk)
        rsize = ctypes.c_uint32(0)

        if self.bit_depth == SampleBitDepth.BIT_DEPTH_16:
            pcm_buf = (ctypes.c_int16 * (max_samples_per_frame * channels))()
        else:
            pcm_buf = (ctypes.c_int32 * (max_samples_per_frame * channels))()

        frames_decoded = self._lib.iamfkit_decoder_decode(
            self._handle,
            c_buf,
            len(data_chunk),
            ctypes.byref(rsize),
            ctypes.cast(pcm_buf, ctypes.c_void_p),
        )

        if frames_decoded <= 0:
            dtype = np.float32 if self.output_format == OutputFormat.FLOAT32 else (
                np.int16 if self.output_format == OutputFormat.INT16 else np.int32
            )
            return np.empty((0, channels), dtype=dtype), rsize.value

        total_samples = frames_decoded * channels

        if self.bit_depth == SampleBitDepth.BIT_DEPTH_16:
            raw_arr = np.frombuffer(pcm_buf, dtype=np.int16, count=total_samples)
            arr = raw_arr.reshape(frames_decoded, channels)
            if self.output_format == OutputFormat.FLOAT32:
                return (arr / 32768.0).astype(np.float32), rsize.value
            return arr, rsize.value
        else:
            raw_arr = np.frombuffer(pcm_buf, dtype=np.int32, count=total_samples)
            arr = raw_arr.reshape(frames_decoded, channels)
            if self.output_format == OutputFormat.FLOAT32:
                return (arr / 2147483648.0).astype(np.float32), rsize.value
            elif self.output_format == OutputFormat.INT16:
                return (arr >> 16).astype(np.int16), rsize.value
            return arr, rsize.value
