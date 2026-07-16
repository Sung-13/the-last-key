# Adds the TheLastKeyWidget extension target to the Xcode project.
# One-shot setup script (kept for reference / re-runs on a clean checkout):
#   GEM_PATH=~/.gem/ruby/2.6.0 /usr/bin/ruby tools/add_widget_target.rb
require 'xcodeproj'

PROJECT_PATH = 'TheLastKey/TheLastKey.xcodeproj'.freeze

proj = Xcodeproj::Project.open(PROJECT_PATH)
app  = proj.targets.find { |t| t.name == 'TheLastKey' }
raise 'app target not found' unless app
raise 'widget target already exists' if proj.targets.any? { |t| t.name == 'TheLastKeyWidget' }

widget = proj.new_target(:app_extension, 'TheLastKeyWidget', :ios, '17.0')

widget.build_configurations.each do |c|
  c.build_settings.merge!(
    'GENERATE_INFOPLIST_FILE' => 'YES',
    'INFOPLIST_FILE' => 'Config/TheLastKeyWidgetInfo.plist',
    'INFOPLIST_KEY_CFBundleDisplayName' => 'The Last Key',
    'PRODUCT_BUNDLE_IDENTIFIER' => 'com.sung13.TheLastKey.TheLastKeyWidget',
    'PRODUCT_NAME' => '$(TARGET_NAME)',
    'IPHONEOS_DEPLOYMENT_TARGET' => '17.0',
    'SWIFT_VERSION' => '5.0',
    'CODE_SIGN_STYLE' => 'Automatic',
    'CODE_SIGN_ENTITLEMENTS' => 'Config/TheLastKeyWidget.entitlements',
    'SKIP_INSTALL' => 'YES',
    'MARKETING_VERSION' => '1.0',
    'CURRENT_PROJECT_VERSION' => '1',
    'TARGETED_DEVICE_FAMILY' => '1,2',
    'LD_RUNPATH_SEARCH_PATHS' => [
      '$(inherited)',
      '@executable_path/Frameworks',
      '@executable_path/../../Frameworks',
    ]
  )
  # Deliberately NOT setting SWIFT_DEFAULT_ACTOR_ISOLATION=MainActor here:
  # TimelineProvider's nonisolated requirements clash with it.
end

# Synchronized folders: TheLastKeyWidget/ (widget only) and Shared/ (both targets).
def new_sync_group(proj, path)
  group = proj.new(Xcodeproj::Project::Object::PBXFileSystemSynchronizedRootGroup)
  group.path = path
  group.source_tree = '<group>'
  proj.main_group.children << group
  group
end

widget_group = new_sync_group(proj, 'TheLastKeyWidget')
shared_group = new_sync_group(proj, 'Shared')
widget.file_system_synchronized_groups << widget_group
widget.file_system_synchronized_groups << shared_group
app.file_system_synchronized_groups << shared_group

app.add_dependency(widget)

embed = app.new_copy_files_build_phase('Embed Foundation Extensions')
embed.dst_subfolder_spec = '13' # PlugIns
embed.dst_path = ''
build_file = embed.add_file_reference(widget.product_reference)
build_file.settings = { 'ATTRIBUTES' => ['RemoveHeadersOnCopy'] }

app.build_configurations.each do |c|
  c.build_settings['CODE_SIGN_ENTITLEMENTS'] = 'Config/TheLastKey.entitlements'
end

proj.save

# --- Post-save sanity checks ---
reopened = Xcodeproj::Project.open(PROJECT_PATH)
w = reopened.targets.find { |t| t.name == 'TheLastKeyWidget' }
a = reopened.targets.find { |t| t.name == 'TheLastKey' }
raise 'bad product type' unless w.product_type == 'com.apple.product-type.app-extension'
raise 'widget sync groups wrong' unless w.file_system_synchronized_groups.map(&:path).sort == %w[Shared TheLastKeyWidget]
raise 'app missing Shared group' unless a.file_system_synchronized_groups.map(&:path).include?('Shared')
raise 'app missing dependency' unless a.dependencies.any? { |d| d.target&.name == 'TheLastKeyWidget' }
raise 'embed phase missing' unless a.copy_files_build_phases.any? { |p| p.name == 'Embed Foundation Extensions' }
raise 'objectVersion changed' unless reopened.root_object.project.object_version == '77'
puts 'OK: widget target added and verified'
