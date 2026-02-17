# Podfile

platform :ios, '14.0'

target 'Asis' do
  use_frameworks! :linkage => :static

  # Core pods
  pod 'SideMenu'
  pod 'Alamofire'
  pod 'DropDown'
  pod 'FloatingPanel'

  # Firebase (you can also use 'Firebase/CoreOnly' + specific pods, but this is fine)
  pod 'FirebaseAnalytics'
  pod 'FirebaseAuth'
  pod 'FirebaseFirestore'
  pod 'Firebase/Database'
end

post_install do |installer|
  installer.pods_project.targets.each do |t|
    t.build_configurations.each do |config|
      # Fix: libarclite missing (deployment target too low)
      config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '14.0'

      # Fix: gRPC-Core compile issues with newer clang
      config.build_settings['CLANG_CXX_LANGUAGE_STANDARD'] = 'c++17'
      config.build_settings['CLANG_CXX_LIBRARY'] = 'libc++'
    end

    # Keep your BoringSSL-GRPC warning-flag cleanup
    if t.name == 'BoringSSL-GRPC'
      t.source_build_phase.files.each do |file|
        next unless file.settings && file.settings['COMPILER_FLAGS']
        flags = file.settings['COMPILER_FLAGS'].split
        flags.reject! { |flag| flag == '-GCC_WARN_INHIBIT_ALL_WARNINGS' }
        file.settings['COMPILER_FLAGS'] = flags.join(' ')
      end
    end
  end
end
