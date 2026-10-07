# Adds an ImeUITests UI-testing bundle (and a scheme) to a scratch Runner.xcodeproj.
require 'xcodeproj'
proj_path, swift = ARGV
proj = Xcodeproj::Project.open(proj_path)
abort('already added') if proj.targets.any? { |t| t.name == 'ImeUITests' }
app = proj.targets.find { |t| t.name == 'Runner' }
ui = proj.new_target(:ui_test_bundle, 'ImeUITests', :ios, '15.0')
ui.build_configurations.each do |c|
  s = c.build_settings
  s['TEST_TARGET_NAME'] = 'Runner'
  s['PRODUCT_NAME'] = '$(TARGET_NAME)'
  s['PRODUCT_BUNDLE_IDENTIFIER'] = 'dev.scratch.ImeUITests'
  s['SWIFT_VERSION'] = '5.0'
  s['GENERATE_INFOPLIST_FILE'] = 'YES'
  s['CODE_SIGNING_ALLOWED'] = 'NO'
  s['IPHONEOS_DEPLOYMENT_TARGET'] = '15.0'
end
ui.add_dependency(app)
group = proj.main_group.new_group('ImeUITests', 'ImeUITests')
ui.add_file_references([group.new_file(swift)])
proj.save
scheme = Xcodeproj::XCScheme.new
scheme.add_build_target(app)
scheme.add_test_target(ui)
scheme.set_launch_target(app)
scheme.save_as(proj_path, 'ImeUITests', true)
puts 'ok'
