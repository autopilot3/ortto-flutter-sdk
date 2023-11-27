#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#
Pod::Spec.new do |s|
  s.name             = 'ortto_flutter_sdk_ios'
  s.version          = '0.0.1'
  s.summary          = 'An iOS implementation of the ortto_flutter_sdk plugin.'
  s.description      = <<-DESC
  An iOS implementation of the ortto_flutter_sdk plugin.
                       DESC
  s.homepage         = 'https://ortto.com'
  s.license          = { :type => 'BSD', :file => '../LICENSE' }
  s.author           = { 'Ortto' => 'email@example.com' }
  s.source           = { :path => '.' }
  s.source_files = 'Classes/**/*'
  s.platform = :ios, '9.0'

  # Flutter.framework does not contain a i386 slice.
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }
  s.swift_version = '5.0'

  # Dependencies
  s.dependency 'Flutter'
  s.dependency 'OrttoSDKCore'
  s.dependency 'OrttoInAppNotifications'
  s.dependency 'OrttoPushMessagingFCM'
end
