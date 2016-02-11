require_relative '../../../../../../lib/bookbinder/config/configuration'
require_relative '../../../../../../lib/bookbinder/commands/components/bind/directory_preparer'
require_relative '../../../../../../lib/bookbinder/commands/components/bind/layout_preparer'
require_relative '../../../../../../lib/bookbinder/local_filesystem_accessor'
require_relative '../../../../../../lib/bookbinder/values/output_locations'

module Bookbinder
  module Commands::Components
    module Bind
      describe DirectoryPreparer do
        describe "#prepare_directories" do
          it "empties and then populates output and final app directories" do
            config = Config::Configuration.new({})
            output_locations = OutputLocations.new(final_app_dir: 'final/app/dir', context_dir: '.')
            ref_override = nil
            cloner = instance_double('Ingest::LocalFilesystemCloner')
            fs = instance_double('LocalFilesystemAccessor')
            layout_preparer = instance_double('LayoutPreparer')

            expect(fs).to receive(:remove_directory).with(output_locations.output_dir).ordered
            expect(fs).to receive(:empty_directory).with(output_locations.final_app_dir).ordered

            expect(fs).to receive(:copy_contents).with('fake/gem/root/template_app', output_locations.final_app_dir).ordered
            expect(fs).to receive(:copy_contents).with('fake/gem/root/master_middleman', output_locations.site_generator_home).ordered

            expect(LayoutPreparer).to receive(:new).with(fs) { layout_preparer }
            expect(layout_preparer).to receive(:prepare).with(output_locations, cloner, ref_override, config)

            DirectoryPreparer.new(fs).prepare_directories(
              config,
              Pathname('fake/gem/root'),
              output_locations,
              cloner,
              ref_override: ref_override,
            )
          end
        end
      end
    end
  end
end
