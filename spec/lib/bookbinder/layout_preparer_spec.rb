require_relative '../../../lib/bookbinder/commands/components/bind/layout_preparer'
require_relative '../../../lib/bookbinder/config/configuration'
require_relative '../../../lib/bookbinder/local_filesystem_accessor'
require_relative '../../../lib/bookbinder/values/output_locations'

module Bookbinder
  module Commands::Components
    module Bind
      describe LayoutPreparer do
        let(:null_dep) { double('dependency').as_null_object }
        let(:fs) { instance_double('Bookbinder::LocalFilesystemAccessor')}
        let(:output_locations) { OutputLocations.new(context_dir: '.') }
        let(:cloner) { double('cloner') }

        context "with no layout repo specified" do
          it "copies the local master_middleman directory" do
            config = Config::Configuration.new({})

            expect(fs).to receive(:copy_contents).
                with(File.absolute_path('master_middleman'), output_locations.site_generator_home)

            LayoutPreparer.new(fs).prepare(output_locations, null_dep, null_dep, config)
          end
        end

        context "with a layout repo specified" do
          context "and no ref given" do
            it "copies the specified repo and the local master_middleman directory" do
              config = Config::Configuration.new({layout_repo: 'universal-layout'})

              expect(cloner).to receive(:call).
                  with(source_repo_name: 'universal-layout',
                       source_ref: nil,
                       destination_parent_dir: anything) { double('cloned thing', path: 'our/repo/path')}

              expect(fs).to receive(:copy_contents).
                  with('our/repo/path', output_locations.site_generator_home).ordered

              expect(fs).to receive(:copy_contents).
                  with(File.absolute_path('master_middleman'), output_locations.site_generator_home).ordered

              LayoutPreparer.new(fs).prepare(output_locations, cloner, nil, config)
            end
          end

          context "with a ref specified" do
            it "copies the specified repo at the specified ref and the local master_middleman directory" do
              config = Config::Configuration.new(
                { layout_repo: 'universal-layout', layout_repo_ref: 'some ref' }
              )

              expect(cloner).to receive(:call).
                  with(source_repo_name: 'universal-layout',
                       source_ref: 'some ref',
                       destination_parent_dir: anything) { double('cloned thing', path: 'our/repo/path') }

              expect(fs).to receive(:copy_contents).
                  with('our/repo/path', output_locations.site_generator_home).ordered

              expect(fs).to receive(:copy_contents).
                  with(File.absolute_path('master_middleman'), output_locations.site_generator_home).ordered

              LayoutPreparer.new(fs).prepare(output_locations, cloner, nil, config)
            end

            context "with ref override" do
              it "copies the specified repo at master and the local master_middleman directory" do
                ref_override = 'override this'

                config = Config::Configuration.new(
                  { layout_repo: 'universal-layout', layout_repo_ref: 'some ref' }
                )

                expect(cloner).to receive(:call).
                    with(source_repo_name: 'universal-layout',
                         source_ref: 'override this',
                         destination_parent_dir: anything) { double('cloned thing', path: 'our/repo/path') }

                expect(fs).to receive(:copy_contents).
                    with('our/repo/path', output_locations.site_generator_home).ordered

                expect(fs).to receive(:copy_contents).
                    with(File.absolute_path('master_middleman'), output_locations.site_generator_home).ordered

                LayoutPreparer.new(fs).prepare(output_locations, cloner, ref_override, config)
              end
            end
          end
        end
      end
    end
  end
end
