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

        def prepare_directories(config, gem_root, locations)
          file_system_accessor.remove_directory(locations.output_dir)
          file_system_accessor.remove_directory(locations.final_app_dir)

          copy_directory_from_gem(gem_root, 'template_app', locations.final_app_dir)
          copy_directory_from_gem(gem_root, 'master_middleman', locations.site_generator_home)
          file_system_accessor.copy_contents(locations.layout_repo_dir, locations.site_generator_home)

          config.versions.each do |version|
            copy_index_file_from_version_to_master_middleman(version, locations.source_for_site_generator, config.book_repo_url)
          end
        end

        private

        attr_reader :logger, :file_system_accessor, :version_control_system

        def copy_index_file_from_version_to_master_middleman(version, dest_dir, url)
          clone_dir_name = Ingest::DestinationDirectory.new(url)
          Dir.mktmpdir(version) do |tmpdir|
            version_control_system.clone(url,
                                         clone_dir_name,
                                         path: tmpdir,
                                         checkout: version)
            index_source_dir = Pathname(tmpdir).join(clone_dir_name, 'master_middleman', source_dir_name)
            index_dest_dir = File.join(dest_dir, version)
            file_system_accessor.make_directory(index_dest_dir)

            Dir.glob(index_source_dir.join('index.*')) do |f|
              file_system_accessor.copy(File.expand_path(f), index_dest_dir)
            end
          end
        end

        def copy_directory_from_gem(gem_root, dir, output_dir)
          file_system_accessor.copy_contents(File.join(gem_root, dir), output_dir)
        end
      end
    end
  end
end
