Pod::Spec.new do |s|
  s.name              = 'ortto_flutter_sdk_ios'
  s.version           = '1.8.4'
  s.summary           = 'OrttoSDK'
  s.homepage          = 'https://github.com/autopilot3/ortto-push-ios-sdk'
  s.license           = { :type => 'MIT', :file => 'LICENSE' }
  s.author            = { 'Ortto.com Team' => 'help@ortto.com' }
  s.source            = { :git => 'https://github.com/autopilot3/ortto-push-ios-sdk.git', :tag => s.version.to_s }
  s.source_files      = 'Classes/**/*'
  s.documentation_url = 'https://help.ortto.com/developer/latest/developer-guide/push-sdks/'
  s.ios.deployment_target = '15.0'
  s.platform          = :ios, '15.0'

  # Flutter.framework does not contain a i386 slice.
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }
  s.swift_version = '5.0'

  # Dependencies
  s.dependency 'Flutter'
  s.dependency 'OrttoSDKCore', '1.8.4'
  s.dependency 'OrttoInAppNotifications', '1.8.4'
  s.dependency 'OrttoPushMessagingFCM', '1.8.4'
end
