import 'dart:ffi';
import 'dart:io';
import 'iamfkit_bindings_generated.dart';

const String _libName = 'iamfkit';

final DynamicLibrary _dylib = () {
  if (Platform.isMacOS || Platform.isIOS) {
    return DynamicLibrary.process();
  }
  if (Platform.isAndroid || Platform.isLinux) {
    return DynamicLibrary.open('libiamf.so');
  }
  if (Platform.isWindows) {
    return DynamicLibrary.open('iamf.dll');
  }
  throw UnsupportedError('Unknown platform: ${Platform.operatingSystem}');
}();

/// The bindings to the native iamfkit C wrapper library.
final IamfKitBindings bindings = IamfKitBindings(_dylib);

export 'iamfkit_bindings_generated.dart';
