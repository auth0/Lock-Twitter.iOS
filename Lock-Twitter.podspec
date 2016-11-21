Pod::Spec.new do |s|
  s.name             = "Lock-Twitter"
  s.version          = "1.2.1"
  s.summary          = "Twitter Native Integration for Auth0 Lock"
  s.description      = <<-DESC
                      [![Auth0](https://i.cloudup.com/1vaSVATKTL.png)](http://auth0.com)
                      Plugin for [Auth0 Lock](https://github.com/auth0/Lock.iOS-OSX) that handles authentication using Twitter native integration.
                       DESC
  s.homepage         = "https://github.com/auth0/Lock-Twitter.iOS"
  s.license          = 'MIT'
  s.author           = { "Auth0" => "support@auth0.com", "Hernan Zalazar" => "hernan@auth0.com" }
  s.source           = { :git => "https://github.com/auth0/Lock-Twitter.iOS.git", :tag => s.version.to_s }
  s.social_media_url = 'https://twitter.com/auth0'

  s.platform     = :ios, '7.0'
  s.requires_arc = true

  s.public_header_files = 'Pod/Classes/*.h'
  s.source_files = 'Pod/Classes/**/*.{h,m}'
  s.module_name = 'LockTwitter'

  s.dependency 'Lock/Core', '~> 1.26'
  s.dependency 'AFNetworking', '~> 3.0'
  s.dependency 'TWReverseAuth', '~> 0.1.0'
  s.dependency 'PSAlertView', '~> 2.0'
  s.dependency 'CocoaLumberjack', '~> 2.0'
  s.frameworks  = 'Social', 'Accounts', 'Twitter'
end
