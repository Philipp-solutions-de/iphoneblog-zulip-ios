Pod::Spec.new do |s|
  s.name             = 'iphoneblog_native'
  s.version          = '0.0.1'
  s.summary          = 'APNs token and sign-in sheet for the iphoneblog Zulip app, without Firebase.'
  s.homepage         = 'https://github.com/Philipp-solutions-de/iphoneblog-zulip-ios'
  s.license          = { :type => 'Apache-2.0' }
  s.author           = { 'Philipp Solutions' => 'https://philipp-solutions.de' }
  s.source           = { :path => '.' }
  s.source_files     = 'Classes/**/*'
  s.dependency 'Flutter'
  s.platform         = :ios, '15.0'
  s.swift_version    = '5.0'
end
