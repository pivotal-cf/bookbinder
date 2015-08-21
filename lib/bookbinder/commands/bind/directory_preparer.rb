module Bookbinder
  module Commands
    module BindComponents
      class DirectoryPreparer
        include Bookbinder::DirectoryHelperMethods

        def initialize(fs)
          @fs = fs
        end

        def prepare_directories(config, gem_root, output_locations, cloner)
          fs.remove_directory(output_locations.output_dir)
          fs.empty_directory(output_locations.final_app_dir)

          copy_directory_from_gem(gem_root, 'template_app', output_locations.final_app_dir)
          copy_directory_from_gem(gem_root, 'master_middleman', output_locations.site_generator_home)

          layout_repo_path = fetch_layout_repo(config, cloner)
          fs.copy_contents(layout_repo_path, output_locations.site_generator_home)
        end

        private

        attr_reader :fs

        def copy_directory_from_gem(gem_root, dir, output_dir)
          fs.copy_contents(File.join(gem_root, dir), output_dir)
        end

        def fetch_layout_repo(config, cloner)
          if config.has_option?('layout_repo')
            cloned_repo = cloner.call(source_repo_name: config.layout_repo,
                          destination_parent_dir: Dir.mktmpdir)
            cloned_repo.path
          else
            File.absolute_path('master_middleman')
          end
        end
      end
    end
  end
end
