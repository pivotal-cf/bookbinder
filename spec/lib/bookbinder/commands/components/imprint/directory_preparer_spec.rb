require_relative '../../../../../../lib/bookbinder/config/configuration'
require_relative '../../../../../../lib/bookbinder/commands/components/imprint/directory_preparer'
require_relative '../../../../../../lib/bookbinder/local_filesystem_accessor'
require_relative '../../../../../../lib/bookbinder/values/output_locations'

module Bookbinder
  module Commands::Components
    module Imprint
      describe DirectoryPreparer do
        describe "#prepare_directories" do
          it "empties output and artifacts/pdfs directories" do
            output_locations = OutputLocations.new(final_app_dir: 'final/app/dir', context_dir: '.')
            fs = instance_double(LocalFilesystemAccessor)

            expect(fs).to receive(:empty_directory).with(output_locations.output_dir).ordered
            expect(fs).to receive(:make_directory).with(output_locations.pdf_from_preprocessing_dir).ordered

            expect(fs).to receive(:empty_directory).with(output_locations.pdf_artifact_dir)

            DirectoryPreparer.new(fs).prepare_directories(output_locations)
          end
        end
      end
    end
  end
end
