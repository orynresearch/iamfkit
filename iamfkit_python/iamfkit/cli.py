import argparse
import sys
import os

from .api import decode_to_wav, decode_file
from .enums import SoundSystem, OutputFormat


def main():
    parser = argparse.ArgumentParser(
        prog="iamfkit",
        description="IAMF Kit — Command-line decoder for IAMF / Eclipsa Audio files.",
    )
    parser.add_argument("input", help="Path to input .iamf file")
    parser.add_argument("output", nargs="?", help="Path to output .wav file (optional)")
    parser.add_argument(
        "--layout",
        choices=["stereo", "binaural", "5.1", "7.1.4"],
        default="binaural",
        help="Output speaker layout / rendering mode (default: binaural)",
    )
    parser.add_argument(
        "--format",
        choices=["int16", "int32", "float32"],
        default="float32",
        help="PCM output sample format (default: float32)",
    )

    args = parser.parse_args()

    layout_map = {
        "stereo": SoundSystem.SOUND_SYSTEM_STEREO,
        "binaural": SoundSystem.SOUND_SYSTEM_BINAURAL,
        "5.1": SoundSystem.SOUND_SYSTEM_B_0_5_0,
        "7.1.4": SoundSystem.SOUND_SYSTEM_F_7_1_4,
    }
    sound_system = layout_map[args.layout]

    if args.output:
        print(f"Decoding {args.input} -> {args.output} ({args.layout})...")
        out_path = decode_to_wav(args.input, args.output, sound_system=sound_system)
        print(f"✓ Saved: {out_path}")
    else:
        pcm, sr, channels = decode_file(
            args.input, output_format=args.format, sound_system=sound_system
        )
        print(f"✓ Decoded {args.input}: {pcm.shape[0]} frames, {channels} channels @ {sr}Hz ({args.format})")


if __name__ == "__main__":
    main()
