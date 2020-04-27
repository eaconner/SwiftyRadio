#
# Be sure to run `pod lib lint SwiftyRadio.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name					= 'SwiftyRadio'
  s.version					= '1.5.0'
  s.summary					= 'Simple and easy way to build streaming radio apps for iOS, tvOS, & macOS'
  s.description				= <<-DESC
SwiftyRadio is an open source cross-platform streaming radio framework for iOS, tvOS, & macOS.
							DESC
  s.homepage				= 'https://github.com/eaconner/SwiftyRadio'
  s.license					= { :type => 'MIT', :file => 'LICENSE' }
  s.author					= { 'Eric Conner' => 'eric@ericconnerapps.com' }
  s.source					= { :git => 'https://github.com/eaconner/SwiftyRadio.git', :tag => s.version.to_s }
  s.social_media_url		= 'https://twitter.com/ericconnerapps'
  s.ios.deployment_target	= '9.1'
  s.tvos.deployment_target	= '9.0'
  s.osx.deployment_target	= '10.12'
  s.source_files			= 'Sources/*.{h,swift}'
  s.requires_arc			= true
  s.swift_version			= '5.0'
  s.pod_target_xcconfig		= { 'SWIFT_VERSION' => '5.0' }
end
