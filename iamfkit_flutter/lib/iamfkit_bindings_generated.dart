// ignore_for_file: type=lint, unused_import, camel_case_types, non_constant_identifier_names, constant_identifier_names

import 'dart:ffi';
import 'package:ffi/ffi.dart';

final class IamfKitStreamInfoNative extends Struct {
  @Uint32()
  external int sampleRate;

  @Uint32()
  external int numChannels;

  @Uint32()
  external int maxFrameSize;

  @Uint32()
  external int audioElementCount;

  @Uint32()
  external int mixPresentationCount;
}

class IamfKitBindings {
  final DynamicLibrary _lib;

  IamfKitBindings(DynamicLibrary dynamicLibrary) : _lib = dynamicLibrary;

  Pointer<Void> iamfkit_decoder_open() {
    return _iamfkit_decoder_open();
  }

  late final _iamfkit_decoder_openPtr =
      _lib.lookup<NativeFunction<Pointer<Void> Function()>>('iamfkit_decoder_open');
  late final _iamfkit_decoder_open =
      _iamfkit_decoder_openPtr.asFunction<Pointer<Void> Function()>();

  int iamfkit_decoder_close(Pointer<Void> handle) {
    return _iamfkit_decoder_close(handle);
  }

  late final _iamfkit_decoder_closePtr =
      _lib.lookup<NativeFunction<Int32 Function(Pointer<Void>)>>('iamfkit_decoder_close');
  late final _iamfkit_decoder_close =
      _iamfkit_decoder_closePtr.asFunction<int Function(Pointer<Void>)>();

  int iamfkit_decoder_set_sound_system(Pointer<Void> handle, int soundSystem) {
    return _iamfkit_decoder_set_sound_system(handle, soundSystem);
  }

  late final _iamfkit_decoder_set_sound_systemPtr =
      _lib.lookup<NativeFunction<Int32 Function(Pointer<Void>, Int32)>>('iamfkit_decoder_set_sound_system');
  late final _iamfkit_decoder_set_sound_system =
      _iamfkit_decoder_set_sound_systemPtr.asFunction<int Function(Pointer<Void>, int)>();

  int iamfkit_decoder_set_bit_depth(Pointer<Void> handle, int bitDepth) {
    return _iamfkit_decoder_set_bit_depth(handle, bitDepth);
  }

  late final _iamfkit_decoder_set_bit_depthPtr =
      _lib.lookup<NativeFunction<Int32 Function(Pointer<Void>, Int32)>>('iamfkit_decoder_set_bit_depth');
  late final _iamfkit_decoder_set_bit_depth =
      _iamfkit_decoder_set_bit_depthPtr.asFunction<int Function(Pointer<Void>, int)>();

  int iamfkit_decoder_set_normalization_loudness(Pointer<Void> handle, double loudness) {
    return _iamfkit_decoder_set_normalization_loudness(handle, loudness);
  }

  late final _iamfkit_decoder_set_normalization_loudnessPtr =
      _lib.lookup<NativeFunction<Int32 Function(Pointer<Void>, Float)>>('iamfkit_decoder_set_normalization_loudness');
  late final _iamfkit_decoder_set_normalization_loudness =
      _iamfkit_decoder_set_normalization_loudnessPtr.asFunction<int Function(Pointer<Void>, double)>();

  int iamfkit_decoder_enable_peak_limiter(Pointer<Void> handle, int enable) {
    return _iamfkit_decoder_enable_peak_limiter(handle, enable);
  }

  late final _iamfkit_decoder_enable_peak_limiterPtr =
      _lib.lookup<NativeFunction<Int32 Function(Pointer<Void>, Int32)>>('iamfkit_decoder_enable_peak_limiter');
  late final _iamfkit_decoder_enable_peak_limiter =
      _iamfkit_decoder_enable_peak_limiterPtr.asFunction<int Function(Pointer<Void>, int)>();

  int iamfkit_decoder_set_head_rotation(Pointer<Void> handle, double w, double x, double y, double z) {
    return _iamfkit_decoder_set_head_rotation(handle, w, x, y, z);
  }

  late final _iamfkit_decoder_set_head_rotationPtr =
      _lib.lookup<NativeFunction<Int32 Function(Pointer<Void>, Float, Float, Float, Float)>>('iamfkit_decoder_set_head_rotation');
  late final _iamfkit_decoder_set_head_rotation =
      _iamfkit_decoder_set_head_rotationPtr.asFunction<int Function(Pointer<Void>, double, double, double, double)>();

  int iamfkit_decoder_configure(
    Pointer<Void> handle,
    Pointer<Uint8> data,
    int size,
    Pointer<Uint32> consumed,
    Pointer<Int32> isConfigured,
  ) {
    return _iamfkit_decoder_configure(handle, data, size, consumed, isConfigured);
  }

  late final _iamfkit_decoder_configurePtr =
      _lib.lookup<NativeFunction<Int32 Function(Pointer<Void>, Pointer<Uint8>, Uint32, Pointer<Uint32>, Pointer<Int32>)>>('iamfkit_decoder_configure');
  late final _iamfkit_decoder_configure =
      _iamfkit_decoder_configurePtr.asFunction<int Function(Pointer<Void>, Pointer<Uint8>, int, Pointer<Uint32>, Pointer<Int32>)>();

  int iamfkit_decoder_decode(
    Pointer<Void> handle,
    Pointer<Uint8> data,
    int size,
    Pointer<Uint32> consumed,
    Pointer<Void> pcmOutput,
  ) {
    return _iamfkit_decoder_decode(handle, data, size, consumed, pcmOutput);
  }

  late final _iamfkit_decoder_decodePtr =
      _lib.lookup<NativeFunction<Int32 Function(Pointer<Void>, Pointer<Uint8>, Uint32, Pointer<Uint32>, Pointer<Void>)>>('iamfkit_decoder_decode');
  late final _iamfkit_decoder_decode =
      _iamfkit_decoder_decodePtr.asFunction<int Function(Pointer<Void>, Pointer<Uint8>, int, Pointer<Uint32>, Pointer<Void>)>();

  int iamfkit_decoder_get_info(Pointer<Void> handle, Pointer<IamfKitStreamInfoNative> outInfo) {
    return _iamfkit_decoder_get_info(handle, outInfo);
  }

  late final _iamfkit_decoder_get_infoPtr =
      _lib.lookup<NativeFunction<Int32 Function(Pointer<Void>, Pointer<IamfKitStreamInfoNative>)>>('iamfkit_decoder_get_info');
  late final _iamfkit_decoder_get_info =
      _iamfkit_decoder_get_infoPtr.asFunction<int Function(Pointer<Void>, Pointer<IamfKitStreamInfoNative>)>();
}
