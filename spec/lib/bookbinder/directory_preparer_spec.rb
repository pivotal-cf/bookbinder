require_relative '../../../lib/bookbinder/config/configuration'
require_relative '../../../lib/bookbinder/commands/bind/directory_preparer'
require_relative '../../../lib/bookbinder/values/output_locations'


module Bookbinder
  module Commands
    module BindComponents
      describe DirectoryPreparer do
        describe "#prepare_directories" do
          context "when layout repo is not specified in config.yml" do
            it "empties and then populates output and final app directories" do
              config = Config::Configuration.new({})
              output_locations = OutputLocations.new(final_app_dir: 'final/app/dir', context_dir: '.')
              cloner = instance_double('Ingest::LocalFilesystemCloner')
              fs = instance_double('LocalFilesystemAccessor')

              expect(fs).to receive(:remove_directory).with(output_locations.output_dir).ordered
              expect(fs).to receive(:empty_directory).with(output_locations.final_app_dir).ordered

              expect(fs).to receive(:copy_contents).with('fake/gem/root/template_app', output_locations.final_app_dir).ordered
              expect(fs).to receive(:copy_contents).with('fake/gem/root/master_middleman', output_locations.site_generator_home).ordered

              expect(fs).to receive(:copy_contents).with(File.absolute_path('master_middleman'), output_locations.site_generator_home).ordered

              DirectoryPreparer.new(fs).prepare_directories(config,
                Pathname('fake/gem/root'),
                output_locations,
                cloner)
            end
          end

          context "when layout repo specified in config.yml" do
            it "empties and then populates output, final app, and layout directories" do
              config = Config::Configuration.new({layout_repo: 'coolest-org/coolest-layout'})
              output_locations = OutputLocations.new(final_app_dir: 'final/app/dir', context_dir: '.')
              working_copy = instance_double('Ingest::WorkingCopy', path: Pathname('path/to/working/copy'))
              cloner = instance_double('Ingest::LocalFilesystemCloner')
              fs = instance_double('LocalFilesystemAccessor', remove_directory: nil, empty_directory: nil)

              expect(fs).to receive(:copy_contents).with('fake/gem/root/template_app', output_locations.final_app_dir).ordered
              expect(fs).to receive(:copy_contents).with('fake/gem/root/master_middleman', output_locations.site_generator_home).ordered

              expect(cloner).to receive(:call).with(source_repo_name: 'coolest-org/coolest-layout',
                  destination_parent_dir: anything) { working_copy }.ordered

              expect(fs).to receive(:copy_contents).with(Pathname('path/to/working/copy'), output_locations.site_generator_home).ordered

              DirectoryPreparer.new(fs).prepare_directories(config,
                Pathname('fake/gem/root'),
                output_locations,
                cloner)
            end
          end
        end
      end
    end
  end
end
