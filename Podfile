platform :ios, '9.0'

target 'VendingDemo' do
  # Comment the next line if you're not using Swift and don't want to use dynamic frameworks
  use_frameworks!

  # Pods for VendingDemo
  pod 'Moya', git: 'https://github.com/Moya/Moya.git', tag: '8.0.0-beta.1'
  pod 'ObjectMapper', '~> 2.0'
  
  
  post_install do |installer|
      installer.pods_project.targets.each do |target|
          target.build_configurations.each do |config|
              config.build_settings['SWIFT_VERSION'] = '3.0'
          end
      end
  end
end
