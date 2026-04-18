Pod::Spec.new do |s|
  s.name = 'AuraLiteRTNative'
  s.version = '0.1.0'
  s.summary = 'LiteRT-LM native runtime wrapper for Aura iOS'
  s.description = 'Prebuilt XCFramework that exposes the LiteRT-LM iOS runtime to Aura via Objective-C++.'
  s.homepage = 'https://github.com/google-ai-edge/LiteRT-LM'
  s.license = { :type => 'Apache-2.0' }
  s.author = { 'Aura' => 'team@aura.local' }
  s.source = { :path => '.' }
  s.platform = :ios, '13.0'
  s.static_framework = true
  s.vendored_frameworks = 'Frameworks/AuraLiteRTNative.xcframework'
  s.frameworks = [
    'AVFAudio',
    'AVFoundation',
    'AudioToolbox',
    'Foundation',
    'Metal',
    'Accelerate',
    'CoreGraphics',
    'QuartzCore',
  ]
  s.libraries = ['c++', 'z']
  s.pod_target_xcconfig = {
    'CLANG_CXX_LANGUAGE_STANDARD' => 'c++20',
  }
  s.user_target_xcconfig = {
    'FRAMEWORK_SEARCH_PATHS[sdk=iphoneos*]' => '$(inherited) "${PODS_ROOT}/../Frameworks/AuraLiteRTNative.xcframework/ios-arm64"',
    'FRAMEWORK_SEARCH_PATHS[sdk=iphonesimulator*]' => '$(inherited) "${PODS_ROOT}/../Frameworks/AuraLiteRTNative.xcframework/ios-arm64-simulator"',
    'HEADER_SEARCH_PATHS[sdk=iphoneos*]' => '$(inherited) "${PODS_ROOT}/../Frameworks/AuraLiteRTNative.xcframework/ios-arm64/AuraLiteRTNative.framework/Headers"',
    'HEADER_SEARCH_PATHS[sdk=iphonesimulator*]' => '$(inherited) "${PODS_ROOT}/../Frameworks/AuraLiteRTNative.xcframework/ios-arm64-simulator/AuraLiteRTNative.framework/Headers"',
  }
end
