module Bookbinder
  module Commands
    module Components
      module Imprint
        class DirectoryPreparer
          def initialize(fs)
            @fs = fs
          end

          def prepare_directories(output_locations)
            fs.empty_directory(output_locations.output_dir)
            fs.make_directory(output_locations.pdf_from_preprocessing_dir)

            fs.empty_directory(output_locations.pdf_artifact_dir)
          end

          private

          attr_reader :fs
        end
      end
    end
  end
end
