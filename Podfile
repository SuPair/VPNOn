platform :ios, '9.0'
use_frameworks!
inhibit_all_warnings!

def import_networking
  pod 'SPLPing'
end

def import_debugging
  pod 'Reveal-iOS-SDK', :configurations => ['Debug']
end

def import_testing
  pod 'Quick', '~> 0.5.0'
  pod 'Nimble', '2.0.0-rc.2'
end

def import_security
  pod 'KeychainAccess',
    :git    => 'git@github.com:kishikawakatsumi/KeychainAccess.git',
    :branch => 'swift-2.0'
end

def import_ui
  pod 'SnapKit',
    :git    => 'git@github.com:SnapKit/SnapKit.git',
    :branch => 'swift-2.0'

  pod 'PromiseKit/Swift/all',
    :git    => 'git@github.com:mxcl/PromiseKit.git',
    :branch => 'swift-2.0-beta5'
end

def import_i18n
  pod 'Swifternalization',
    :git    => 'git@github.com:tomkowz/Swifternalization.git',
    :branch => 'swift2'
end

target 'VPNOn' do
  import_debugging
  import_ui
  import_i18n
  import_networking
  import_security
end

target 'VPNOnTests' do
  import_testing
end

target 'TodayWidget' do
  import_networking
  import_security
  import_i18n
end

target 'VPNOnKit' do
  import_security
end

target 'VPNOnKitTests' do
  import_testing
  import_security
end

target 'VPNOnWatchKitExtension' do
  platform :watchos, '2.0'
  import_security
end

target 'VPNOnWatchKitApp' do
  platform :watchos, '2.0'
  import_security
end
