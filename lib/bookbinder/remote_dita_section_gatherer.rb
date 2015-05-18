require_relative '../../lib/bookbinder/deprecated_logger'
require_relative '../../lib/bookbinder/values/section'

module Bookbinder
  class RemoteDitaSectionGatherer
    def initialize(version_control_system, view_updater, output_locations)
      @version_control_system = version_control_system
      @view_updater = view_updater
      @output_locations = output_locations
    end

    def gather(dita_section_config_hash)
      dita_section_config_hash.map do |dita_section_config|
        view_updater.log "Gathering " + "#{dita_section_config.fetch('repository').fetch('name')}".cyan
        Section.new(
          output_locations.cloned_preprocessing_dir.join(dita_section_config['directory']),
          dita_section_config.fetch('repository').fetch('name'),
          copied = true,
          output_locations.cloned_preprocessing_dir,
          dita_section_config['directory'],
          'dita_subnav',
          'ditamap_location' => dita_section_config['ditamap_location'],
          'ditaval_location' => dita_section_config['ditaval_location'],
        ).tap do |section|
          version_control_system.clone(
            "git@github.com:#{section.full_name}",
            section.directory_name,
            path: output_locations.cloned_preprocessing_dir,
            checkout: dita_section_config.fetch('repository').fetch('ref', 'master'),
          )
        end
      end
    end

    private

    attr_reader :version_control_system, :view_updater, :output_locations

  end
end
