from enum import Enum, IntEnum
from typing import Union


class SoundSystem(IntEnum):
    """Output sound system layout for IAMF decoding."""
    SOUND_SYSTEM_A_0_2_0 = 0   # Stereo (L, R)
    SOUND_SYSTEM_B_0_5_0 = 1   # 5.0 Surround
    SOUND_SYSTEM_C_0_7_0 = 2   # 7.0 Surround
    SOUND_SYSTEM_D_5_1_2 = 3   # 5.1.2 Surround
    SOUND_SYSTEM_E_5_1_4 = 4   # 5.1.4 Surround
    SOUND_SYSTEM_F_7_1_4 = 5   # 7.1.4 Surround (Dolby Atmos bed)
    SOUND_SYSTEM_G_3_1_2 = 6   # 3.1.2 Surround
    SOUND_SYSTEM_H_7_1_2 = 7   # 7.1.2 Surround
    SOUND_SYSTEM_I_3_1_0 = 8   # 3.1.0 Surround
    SOUND_SYSTEM_J_2_0_0 = 9   # Mono / Dual mono
    SOUND_SYSTEM_12_0_0 = 10  # 12.0.0 Surround
    SOUND_SYSTEM_10_2_0 = 11  # 10.2.0 Surround
    SOUND_SYSTEM_STEREO = 0
    SOUND_SYSTEM_BINAURAL = 99 # Special Binaural 3D rendering flag


LAYOUT_ALIASES = {
    "stereo": SoundSystem.SOUND_SYSTEM_STEREO,
    "binaural": SoundSystem.SOUND_SYSTEM_BINAURAL,
    "3d": SoundSystem.SOUND_SYSTEM_BINAURAL,
    "headphones": SoundSystem.SOUND_SYSTEM_BINAURAL,
    "mono": SoundSystem.SOUND_SYSTEM_J_2_0_0,
    "5.0": SoundSystem.SOUND_SYSTEM_B_0_5_0,
    "5.1": SoundSystem.SOUND_SYSTEM_B_0_5_0,
    "7.0": SoundSystem.SOUND_SYSTEM_C_0_7_0,
    "7.1": SoundSystem.SOUND_SYSTEM_C_0_7_0,
    "5.1.2": SoundSystem.SOUND_SYSTEM_D_5_1_2,
    "5.1.4": SoundSystem.SOUND_SYSTEM_E_5_1_4,
    "7.1.4": SoundSystem.SOUND_SYSTEM_F_7_1_4,
    "3.1.2": SoundSystem.SOUND_SYSTEM_G_3_1_2,
    "7.1.2": SoundSystem.SOUND_SYSTEM_H_7_1_2,
}


def parse_sound_system(value: Union[SoundSystem, str, int]) -> SoundSystem:
    """Parse string layout alias or integer into SoundSystem enum."""
    if isinstance(value, SoundSystem):
        return value
    if isinstance(value, int):
        return SoundSystem(value)
    if isinstance(value, str):
        key = value.lower().strip()
        if key in LAYOUT_ALIASES:
            return LAYOUT_ALIASES[key]
        try:
            return SoundSystem[value.upper()]
        except KeyError:
            pass
    raise ValueError(f"Unknown sound system layout '{value}'. Supported aliases: {list(LAYOUT_ALIASES.keys())}")


class SampleBitDepth(IntEnum):
    """Output sample bit depth."""
    BIT_DEPTH_16 = 16
    BIT_DEPTH_24 = 24
    BIT_DEPTH_32 = 32


class OutputFormat(str, Enum):
    """Output PCM data type format for NumPy arrays."""
    INT16 = "int16"
    INT32 = "int32"
    FLOAT32 = "float32"  # Normalized [-1.0, 1.0]


class IAProfile(IntEnum):
    """IAMF Profile."""
    PROFILE_NONE = 0
    PROFILE_SIMPLE = 1
    PROFILE_BASE = 2
