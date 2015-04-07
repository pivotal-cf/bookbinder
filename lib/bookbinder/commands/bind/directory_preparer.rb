require_relative '../../directory_helpers'

module Bookbinder
  module Commands
    module BindComponents
      class DirectoryPreparer
        include Bookbinder::DirectoryHelperMethods

        def initialize(logger, file_system_accessor, version_control_system, book_repo)
          @logger = logger
          @file_system_accessor = file_system_accessor
          @version_control_system = version_control_system
          @book_repo = book_repo
        end

        def prepare_directories(gem_root, versions, locations)
          forget_sections(locations.output_dir)
          file_system_accessor.remove_directory(File.join(locations.final_app_dir, '.'))
          file_system_accessor.remove_directory(locations.dita_home_dir)

          copy_directory_from_gem(gem_root, 'template_app', locations.final_app_dir)
          copy_directory_from_gem(gem_root, 'master_middleman', locations.site_generator_home)
          file_system_accessor.copy(File.join(locations.layout_repo_dir, '.'), locations.site_generator_home)

          versions.each do |version|
            copy_index_file_from_version_to_master_middleman(version, locations.source_for_site_generator)
          end
        end

        private

        attr_reader :logger, :file_system_accessor, :version_control_system, :book_repo

        def copy_index_file_from_version_to_master_middleman(version, dest_dir)
          Dir.mktmpdir(version) do |tmpdir|
            book = Book.from_remote(logger: logger,
                                    full_name: book_repo,
                                    destination_dir: tmpdir,
                                    ref: version,
                                    git_accessor: version_control_system)
            index_source_dir = File.join(tmpdir, book.directory, 'master_middleman', source_dir_name)
            index_dest_dir = File.join(dest_dir, version)
            file_system_accessor.make_directory(index_dest_dir)

            Dir.glob(File.join(index_source_dir, 'index.*')) do |f|
              file_system_accessor.copy(File.expand_path(f), index_dest_dir)
            end
          end
        end

        def forget_sections(middleman_scratch)
          file_system_accessor.remove_directory File.join middleman_scratch, '.'
        end

        def copy_directory_from_gem(gem_root, dir, output_dir)
          file_system_accessor.copy File.join(gem_root, "#{dir}/."), output_dir
        end
      end
    end
  end
end
