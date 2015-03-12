module Bookbinder
  class LocalDitaSectionGatherer
    def initialize(output_locations)
      @output_locations = output_locations
    end

    def gather(dita_section_config_hash)
      dita_section_config_hash.map do |dita_section_config|
        relative_path_to_dita_map = dita_section_config['ditamap_location']
        full_name = dita_section_config.fetch('repository', {}).fetch('name')
        target_ref = dita_section_config.fetch('repository', {})['ref']
        directory = dita_section_config['directory']
        path_to_local_copy = output_locations.local_repo_dir.join(directory)

        DitaSection.new(path_to_local_copy,
                        relative_path_to_dita_map,
                        full_name,
                        target_ref,
                        directory,
                        output_locations)
      end
    end

    private

    attr_reader :output_locations

  end
end
