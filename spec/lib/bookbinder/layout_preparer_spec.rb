require_relative '../../../lib/bookbinder/commands/bind/layout_preparer'
require_relative '../../../lib/bookbinder/config/configuration'
require_relative '../../../lib/bookbinder/local_filesystem_accessor'
require_relative '../../../lib/bookbinder/values/output_locations'

module Bookbinder
  module Commands
    module BindComponents
      describe LayoutPreparer do
        let(:null_dep) { double('dependency').as_null_object }

        context "with no layout repo specified" do
          it "copies the local master_middleman directory" do
            fs = instance_double('Bookbinder::LocalFilesystemAccessor')
            output_locations = OutputLocations.new(context_dir: '.')
            config = Config::Configuration.new({})

            expect(fs).to receive(:copy_contents).
                with(File.absolute_path('master_middleman'), output_locations.site_generator_home)

            LayoutPreparer.new(fs).prepare(output_locations, null_dep, config)
          end
        end

        context "with a layout repo specified" do
          it "copies the specified repo and the local master_middleman directory" do
            cloner = double('cloner')
            config = Config::Configuration.new({layout_repo: 'universal-layout'})
            fs = instance_double('Bookbinder::LocalFilesystemAccessor')
            output_locations = OutputLocations.new(context_dir: '.')

            expect(cloner).to receive(:call).
                with(source_repo_name: 'universal-layout',
                     destination_parent_dir: anything) { double('cloned thing', path: 'our/repo/path')}

            expect(fs).to receive(:copy_contents).
                with('our/repo/path', output_locations.site_generator_home).ordered

            expect(fs).to receive(:copy_contents).
                with(File.absolute_path('master_middleman'), output_locations.site_generator_home).ordered

            LayoutPreparer.new(fs).prepare(output_locations, cloner, config)
          end
        end
      end
    end
  end
end
