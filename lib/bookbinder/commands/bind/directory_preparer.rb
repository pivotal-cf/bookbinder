module Bookbinder
  module Commands
    module BindComponents
      class DirectoryPreparer
        def initialize(fs)
          @fs = fs
        end

        def prepare_directories(gem_root, output_locations, layout_repo_dir)
          fs.remove_directory(output_locations.output_dir)
          fs.empty_directory(output_locations.final_app_dir)
          fs.copy_contents(File.join(gem_root, 'template_app'), output_locations.final_app_dir)
          fs.copy_contents(File.join(gem_root, 'master_middleman'), output_locations.site_generator_home)
          fs.copy_contents(layout_repo_dir, output_locations.site_generator_home)
        end

        private

        attr_reader :fs
      end
    end
  end
end
