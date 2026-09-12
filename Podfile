platform :ios, '15.6'

target 'Asis' do
  use_frameworks! :linkage => :static

  pod 'SideMenu', '~> 6.5'
  pod 'Alamofire', '~> 5.11'
  pod 'FloatingPanel', '~> 3.2'
  pod 'FirebaseAnalytics', '~> 12.19'
  pod 'FirebaseAuth', '~> 12.19'
  pod 'FirebaseFirestore', '~> 12.19'

  target 'AsisTests' do
    inherit! :search_paths
  end
end

post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      minimum = Gem::Version.new('15.6')
      declared = Gem::Version.new(config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] || '0')
      config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = [declared, minimum].max.to_s
    end
  end
end
