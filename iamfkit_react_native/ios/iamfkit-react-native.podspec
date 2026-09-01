#
# CocoaPods spec for iamfkit-react-native
#
Pod::Spec.new do |s|
  s.name         = "iamfkit-react-native"
  s.version      = "0.1.0"
  s.summary      = "React Native & Expo module for decoding IAMF (Immersive Audio Model and Formats) files."
  s.description  = <<-DESC
    React Native & Expo bridge for decoding IAMF spatial audio files via the native libiamfkit C API.
                   DESC
  s.homepage     = "https://github.com/MinoDab492/iamfkit"
  s.license      = { :type => "Source-Available", :file => "../LICENSE" }
  s.authors      = { "Heath Garvin" => "heath.garvin08@icloud.com" }
  s.platforms    = { :ios => "14.0" }
  s.source       = { :git => "https://github.com/MinoDab492/iamfkit.git", :tag => "v#{s.version}" }

  s.source_files = "*.{h,m,mm,swift}", "../../code/include/iamfkit.h"
  s.dependency "React-Core"

  s.vendored_frameworks = "iamf.xcframework"
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'OTHER_LDFLAGS' => '-all_load' }
end
