require_relative 'ingest/local_filesystem_cloner'
require_relative 'local_file_system_accessor'

module Bookbinder
  class LocalDitaSectionGatherer
    def initialize(output_locations)
      @output_locations = output_locations
    end

    def gather(dita_section_config_hash)
      dita_section_config_hash.map do |dita_section_config|
        relative_path_to_dita_map = dita_section_config['ditamap_location']
        relative_path_to_dita_val = dita_section_config['ditaval_location']
        full_name = dita_section_config.fetch('repository', {}).fetch('name')
        target_ref = dita_section_config.fetch('repository', {})['ref']
        desired_destination_directory_name = dita_section_config['directory']
        local_source_directory_name = full_name.split('/').last
        path_to_local_copy = output_locations.local_repo_dir.join(local_source_directory_name)

        cloner = Ingest::LocalFilesystemCloner.new(DeprecatedLogger.new,
                                                   LocalFileSystemAccessor.new,
                                                   output_locations.local_repo_dir)
        working_copy = cloner.call(source_repo_name: full_name,
                                   destination_parent_dir: output_locations.source_for_site_generator,
                                   destination_dir_name: desired_destination_directory_name)

        DitaSection.new(working_copy.copied_to,
                        relative_path_to_dita_map,
                        relative_path_to_dita_val,
                        full_name,
                        target_ref,
                        desired_destination_directory_name,
                        output_locations)
      end
    end

    private

    attr_reader :output_locations

  end
end
