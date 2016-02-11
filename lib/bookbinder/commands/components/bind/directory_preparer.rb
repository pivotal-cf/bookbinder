require_relative 'layout_preparer'

module Bookbinder
  module Commands
    module Components
      module Bind
        class DirectoryPreparer
          def initialize(fs)
            @fs = fs
          end

          def prepare_directories(config, gem_root, output_locations, cloner, ref_override: nil)
            fs.remove_directory(output_locations.output_dir)
            fs.empty_directory(output_locations.final_app_dir)

            copy_directory_from_gem(gem_root, 'template_app', output_locations.final_app_dir)
            copy_directory_from_gem(gem_root, 'master_middleman', output_locations.site_generator_home)

            LayoutPreparer.new(fs).prepare(output_locations, cloner, ref_override, config)
          end

          private

          attr_reader :fs

          def copy_directory_from_gem(gem_root, dir, output_dir)
            fs.copy_contents(File.join(gem_root, dir), output_dir)
          end
        end
      end
    end
  end
end
