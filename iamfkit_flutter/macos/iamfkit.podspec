#
# macOS podspec for iamfkit
#
Pod::Spec.new do |s|
  s.name             = 'iamfkit'
  s.version          = '0.1.0'
  s.summary          = 'Flutter FFI plugin for IAMF (Immersive Audio Model and Formats) decoding.'
  s.description      = <<-DESC
    Provides real-time IAMF audio decoding via the AOMedia libiamf C library,
    exposed to Flutter/Dart through dart:ffi.
                       DESC
  s.homepage         = 'https://github.com/MinoDab492/iamfkit'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Heath Garvin' => 'heath.garvin08@icloud.com' }

  s.source           = { :path => '.' }
  s.source_files     = 'Classes/**/*'
  s.dependency 'FlutterMacOS'
  s.platform         = :osx, '12.0'

  # Vendored universal XCFramework (arm64 + x86_64)
  s.vendored_frameworks = 'iamf_macos.xcframework'

  s.libraries        = 'c++', 'iconv'
  s.frameworks       = 'CoreFoundation'

  s.pod_target_xcconfig = {
    'DEFINES_MODULE' => 'YES',
    'OTHER_LDFLAGS'  => '-all_load'
  }
  s.swift_version = '5.0'
end
