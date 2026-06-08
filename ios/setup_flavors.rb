#!/usr/bin/env ruby
# Crea las build configurations, bundle ids, Run Script y schemes para los
# flavors dev/prod en el proyecto iOS. Idempotente: se puede correr varias veces.
require 'xcodeproj'

project_path = File.join(__dir__, 'Runner.xcodeproj')
project = Xcodeproj::Project.open(project_path)

BASE_MODES = %w[Debug Release Profile].freeze
FLAVORS = %w[dev prod].freeze
DEV_BUNDLE_ID = 'com.camiloagudelo.rideglory.dev'.freeze
PROD_BUNDLE_ID = 'com.camiloagudelo.rideglory'.freeze

runner = project.targets.find { |t| t.name == 'Runner' }
raise 'No se encontró el target Runner' unless runner

# Duplica las configs base -> -dev / -prod en una XCConfigurationList dada.
def ensure_flavor_configs(config_list, project)
  BASE_MODES.each do |mode|
    base = config_list.build_configurations.find { |c| c.name == mode }
    next unless base

    FLAVORS.each do |flavor|
      new_name = "#{mode}-#{flavor}"
      next if config_list.build_configurations.any? { |c| c.name == new_name }

      cfg = project.new(Xcodeproj::Project::Object::XCBuildConfiguration)
      cfg.name = new_name
      cfg.build_settings = Marshal.load(Marshal.dump(base.build_settings))
      cfg.base_configuration_reference = base.base_configuration_reference
      config_list.build_configurations << cfg
    end
  end
end

# 1) Configs a nivel proyecto y en cada target.
ensure_flavor_configs(project.build_configuration_list, project)
project.targets.each do |t|
  ensure_flavor_configs(t.build_configuration_list, project)
end

# 2) Bundle id por flavor solo en el target Runner.
runner.build_configuration_list.build_configurations.each do |cfg|
  case cfg.name
  when /-dev$/
    cfg.build_settings['PRODUCT_BUNDLE_IDENTIFIER'] = DEV_BUNDLE_ID
  when /-prod$/
    cfg.build_settings['PRODUCT_BUNDLE_IDENTIFIER'] = PROD_BUNDLE_ID
  end
end

# 3) Run Script phase que copia el GoogleService-Info.plist del flavor.
script_name = 'Set Firebase plist (flavor)'
unless runner.shell_script_build_phases.any? { |p| p.name == script_name }
  phase = runner.new_shell_script_build_phase(script_name)
  phase.shell_script = '"${PROJECT_DIR}/scripts/set_google_service_plist.sh"'
  phase.show_env_vars_in_log = '0'
  # Moverla ANTES de "Copy Bundle Resources" para que el plist correcto exista.
  runner.build_phases.delete(phase)
  resources_idx = runner.build_phases.index { |p| p.display_name == 'Resources' } || 0
  runner.build_phases.insert(resources_idx, phase)
end

# 4) Schemes dev / prod (Flutter usa el nombre del scheme como flavor).
FLAVORS.each do |flavor|
  scheme = Xcodeproj::XCScheme.new
  scheme.add_build_target(runner)
  scheme.set_launch_target(runner)

  scheme.build_action.entries.each { |e| e.build_for_archiving = true }
  scheme.launch_action.build_configuration = "Debug-#{flavor}"
  scheme.test_action.build_configuration = "Debug-#{flavor}"
  scheme.profile_action.build_configuration = "Profile-#{flavor}"
  scheme.analyze_action.build_configuration = "Debug-#{flavor}"
  scheme.archive_action.build_configuration = "Release-#{flavor}"

  scheme.save_as(project_path, flavor, true)
end

project.save
puts 'OK: flavors dev/prod configurados en el proyecto iOS.'
