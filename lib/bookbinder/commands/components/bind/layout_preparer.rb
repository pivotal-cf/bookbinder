module Bookbinder
  module Commands
    module Components
      module Bind
        class LayoutPreparer
          def initialize(fs)
            @fs = fs
          end

          attr_reader :fs

          def prepare(output_locations, cloner, ref_override, config)
            if config.has_option?('layout_repo')

              cloned_repo = cloner.call(source_repo_name: config.layout_repo,
                                        source_ref: ref_override || config.layout_repo_ref,
                                        destination_parent_dir: Dir.mktmpdir)

              fs.copy_contents(cloned_repo.path, output_locations.site_generator_home)
            end
            fs.copy_contents(File.absolute_path('master_middleman'), output_locations.site_generator_home)
          end
        end
      end
    end
  end
end
