import ctypes
import os
import platform
from ctypes import (
    POINTER,
    Structure,
    c_float,
    c_int,
    c_uint8,
    c_uint32,
    c_void_p,
)

# ------------------------------------------------------------------------------
# Structs matching iamfkit.h
# ------------------------------------------------------------------------------

class IamfKitStreamInfo(Structure):
    _fields_ = [
        ("sample_rate", c_uint32),
        ("num_channels", c_uint32),
        ("max_frame_size", c_uint32),
        ("audio_element_count", c_uint32),
        ("mix_presentation_count", c_uint32),
    ]


# ------------------------------------------------------------------------------
# Shared Library Loader
# ------------------------------------------------------------------------------

def _find_library():
    env_path = os.environ.get("LIBIAMF_PATH")
    if env_path and os.path.exists(env_path):
        return env_path

    system = platform.system().lower()
    lib_name = "libiamf"
    if system == "darwin":
        extensions = [".dylib", ".so"]
    elif system == "windows":
        lib_name = "iamf"
        extensions = [".dll"]
    else:
        extensions = [".so"]

    curr_dir = os.path.dirname(os.path.abspath(__file__))
    project_root = os.path.abspath(os.path.join(curr_dir, "..", ".."))

    search_dirs = [
        curr_dir,
        os.path.join(curr_dir, "lib"),
        os.path.join(project_root, "code", "build_mac_shared"),
        os.path.join(project_root, "code", "build"),
        os.path.join(project_root, "linux"),
        os.path.join(project_root, "windows"),
        os.path.join(project_root, "macos"),
    ]

    for d in search_dirs:
        for ext in extensions:
            target = os.path.join(d, f"{lib_name}{ext}")
            if os.path.exists(target):
                return target

    for ext in extensions:
        filename = f"{lib_name}{ext}"
        try:
            return filename
        except Exception:
            pass

    return f"{lib_name}{extensions[0]}"


_lib = None

def get_lib():
    global _lib
    if _lib is not None:
        return _lib

    lib_path = _find_library()
    try:
        _lib = ctypes.CDLL(lib_path)
    except Exception as e:
        raise RuntimeError(
            f"Failed to load libiamf shared library from '{lib_path}'. "
            "Ensure libiamf is compiled or set LIBIAMF_PATH environment variable."
        ) from e

    _setup_prototypes(_lib)
    return _lib


def _setup_prototypes(lib):
    # iamfkit_decoder_open
    lib.iamfkit_decoder_open.restype = c_void_p
    lib.iamfkit_decoder_open.argtypes = []

    # iamfkit_decoder_close
    lib.iamfkit_decoder_close.restype = c_int
    lib.iamfkit_decoder_close.argtypes = [c_void_p]

    # iamfkit_decoder_set_sound_system
    lib.iamfkit_decoder_set_sound_system.restype = c_int
    lib.iamfkit_decoder_set_sound_system.argtypes = [c_void_p, c_int]

    # iamfkit_decoder_set_bit_depth
    lib.iamfkit_decoder_set_bit_depth.restype = c_int
    lib.iamfkit_decoder_set_bit_depth.argtypes = [c_void_p, c_int]

    # iamfkit_decoder_set_normalization_loudness
    lib.iamfkit_decoder_set_normalization_loudness.restype = c_int
    lib.iamfkit_decoder_set_normalization_loudness.argtypes = [c_void_p, c_float]

    # iamfkit_decoder_enable_peak_limiter
    lib.iamfkit_decoder_enable_peak_limiter.restype = c_int
    lib.iamfkit_decoder_enable_peak_limiter.argtypes = [c_void_p, c_int]

    # iamfkit_decoder_set_head_rotation
    lib.iamfkit_decoder_set_head_rotation.restype = c_int
    lib.iamfkit_decoder_set_head_rotation.argtypes = [c_void_p, c_float, c_float, c_float, c_float]

    # iamfkit_decoder_configure
    lib.iamfkit_decoder_configure.restype = c_int
    lib.iamfkit_decoder_configure.argtypes = [
        c_void_p, POINTER(c_uint8), c_uint32, POINTER(c_uint32), POINTER(c_int)
    ]

    # iamfkit_decoder_decode
    lib.iamfkit_decoder_decode.restype = c_int
    lib.iamfkit_decoder_decode.argtypes = [
        c_void_p, POINTER(c_uint8), c_uint32, POINTER(c_uint32), c_void_p
    ]

    # iamfkit_decoder_get_info
    lib.iamfkit_decoder_get_info.restype = c_int
    lib.iamfkit_decoder_get_info.argtypes = [c_void_p, POINTER(IamfKitStreamInfo)]
