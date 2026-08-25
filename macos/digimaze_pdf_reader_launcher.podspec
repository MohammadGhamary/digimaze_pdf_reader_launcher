#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint digimaze_pdf_reader_launcher.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'digimaze_pdf_reader_launcher'
  s.version          = '0.0.1'
  s.summary          = 'Flutter plugin that launches a platform-native PDF reader in Digimaze application.'
  s.description      = <<-DESC
Flutter plugin that launches a platform-native PDF reader in Digimaze application.
                       DESC
  s.homepage         = 'http://example.com'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Your Company' => 'email@example.com' }

  s.source           = { :path => '.' }
  s.source_files = 'digimaze_pdf_reader_launcher/Sources/digimaze_pdf_reader_launcher/**/*'

  # If your plugin requires a privacy manifest, for example if it collects user
  # data, update the PrivacyInfo.xcprivacy file to describe your plugin's
  # privacy impact, and then uncomment this line. For more information,
  # see https://developer.apple.com/documentation/bundleresources/privacy_manifest_files
  # s.resource_bundles = {'digimaze_pdf_reader_launcher_privacy' => ['digimaze_pdf_reader_launcher/Sources/digimaze_pdf_reader_launcher/PrivacyInfo.xcprivacy']}

  s.dependency 'FlutterMacOS'

  s.platform = :osx, '10.11'
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES' }
  s.swift_version = '5.0'
end
