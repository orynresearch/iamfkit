import 'dart:ffi';
import 'dart:io';
import 'eclipsa_iamf_decoder_bindings_generated.dart';

export 'eclipsa_iamf_decoder_bindings_generated.dart';

const String _libName = 'eclipsa_iamf_decoder';

/// The dynamic library in which the symbols for [EclipsaIamfDecoderBindings] can be found.
final DynamicLibrary _dylib = () {
  if (Platform.isMacOS || Platform.isIOS) {
    try {
      // In Flutter dynamic framework mode
      return DynamicLibrary.open('$_libName.framework/$_libName');
    } catch (_) {
      try {
        // Fallback for static linking / standalone binaries
        return DynamicLibrary.process();
      } catch (e) {
        throw UnsupportedError('Failed to load native library: $e');
      }
    }
  }
  if (Platform.isAndroid || Platform.isLinux) {
    return DynamicLibrary.open('lib$_libName.so');
  }
  if (Platform.isWindows) {
    return DynamicLibrary.open('$_libName.dll');
  }
  throw UnsupportedError('Unknown platform: ${Platform.operatingSystem}');
}();

/// The raw bindings to the native functions.
final EclipsaIamfDecoderBindings bindings = EclipsaIamfDecoderBindings(_dylib);


