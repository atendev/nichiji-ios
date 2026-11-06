# ML Kit Digital Ink has no Swift Package, so it comes through CocoaPods. `make generate` runs `pod install`
# after `xcodegen generate`, because regenerating the project drops the pod integration.
platform :ios, '27.0'
project 'Nichiji.xcodeproj'

target 'Nichiji' do
  pod 'MLKitDigitalInkRecognition', '8.0.0'
end

# ML Kit's dependencies declare iOS 9 to 12, below Xcode 27's minimum.
post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '17.0'
      config.build_settings.delete('EXCLUDED_ARCHS[sdk=iphonesimulator*]')
    end
  end
end

# The ML Kit pods exclude arm64 for the Simulator, and CocoaPods copies that into the app's xcconfig. Xcode 27 has
# no x86_64 Simulator, so the app would have nothing to build. Dropping the exclusion keeps the Simulator on arm64,
# and moving the pod linker flags to `iphoneos` keeps ML Kit's device-only binaries off the Simulator link.
# `MLKitHandwritingModel` compiles only for devices for the same reason.
post_integrate do |installer|
  support = File.join(installer.sandbox.root, 'Target Support Files')
  Dir.glob(File.join(support, '**', '*.xcconfig')).each do |path|
    text = File.read(path)
    edited = text.lines.reject { |line| line.start_with?('EXCLUDED_ARCHS[sdk=iphonesimulator*]') }.join
    if File.basename(path).start_with?('Pods-Nichiji.')
      edited = edited.sub(/^OTHER_LDFLAGS = /, 'OTHER_LDFLAGS[sdk=iphoneos*] = ')
    end
    File.write(path, edited) unless edited == text
  end
end
