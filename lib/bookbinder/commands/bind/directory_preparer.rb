require_relative '../../directory_helpers'
require_relative '../../ingest/destination_directory'

module Bookbinder
  module Commands
    module BindComponents
      class DirectoryPreparer
        include Bookbinder::DirectoryHelperMethods

        def initialize(logger, file_system_accessor, version_control_system)
          @logger = logger
          @file_system_accessor = file_system_accessor
          @version_control_system = version_control_system
        end

        def prepare_directories(config, gem_root, output_locations, layout_repo_dir)
          file_system_accessor.remove_directory(output_locations.output_dir)
          file_system_accessor.empty_directory(output_locations.final_app_dir)

          copy_directory_from_gem(gem_root, 'template_app', output_locations.final_app_dir)
          copy_directory_from_gem(gem_root, 'master_middleman', output_locations.site_generator_home)
          file_system_accessor.copy_contents(layout_repo_dir, output_locations.site_generator_home)
        end

        private

        attr_reader :logger, :file_system_accessor, :version_control_system

        def copy_directory_from_gem(gem_root, dir, output_dir)
          file_system_accessor.copy_contents(File.join(gem_root, dir), output_dir)
        end
      end
    end
  end
end
