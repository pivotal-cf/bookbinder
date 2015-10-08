require_relative '../../../../lib/bookbinder/config/section_config'
require_relative '../../../../lib/bookbinder/preprocessing/dita_preprocessor'
require_relative '../../../../lib/bookbinder/values/output_locations'
require_relative '../../../../lib/bookbinder/values/section'

module Bookbinder
  module Preprocessing
    describe DitaPreprocessor do
      describe 'applicable to' do
        it "is true for sections configured with a default dita subnav" do
          expect(DitaPreprocessor.new(double('formatter'), double('fs'), double('command creator'), double('sheller'))).
            to be_applicable_to(Config::SectionConfig.new('subnav_template' => 'dita_subnav'))
        end

        it "is true for sections configured with a non-default dita subnav" do
          expect(DitaPreprocessor.new(double('formatter'), double('fs'), double('command creator'), double('sheller'))).
            to be_applicable_to(Config::SectionConfig.new('subnav_template' => 'dita_subnav_100'))
        end

        it "is false for anything else" do
          expect(DitaPreprocessor.new(double('formatter'), double('fs'), double('command creator'), double('sheller'))).
            not_to be_applicable_to(Config::SectionConfig.new('subnav_template' => 'something_else'))
        end
      end

      context "for dita sections without a ditamap" do
        it "formats the html for each dita section and copies files into the middleman source directory" do
          dita_formatter = instance_double('Bookbinder::DitaHtmlToMiddlemanFormatter',
            format_subnav: double('subnav').as_null_object)
          fs = instance_double('Bookbinder::LocalFilesystemAccessor', read: double('subnav template'), write: nil)
          stub_const('Bookbinder::Preprocessing::DitaPreprocessor::ACCEPTED_IMAGE_FORMATS', ['img-format'])

          output_locations = OutputLocations.new(context_dir: ".")
          section = Section.new('path-to-repository',
            'full-name',
            'go-here-please',
            'subnav-template',
            nil,
            {})

          formatted_dir = output_locations.formatted_dir.join(section.destination_directory)

          expect(dita_formatter).to receive(:format_html).
              with(output_locations.html_from_preprocessing_dir.join(section.destination_directory),
                formatted_dir).ordered

          expect(fs).to receive(:find_files_with_ext).
              with('img-format', section.path_to_repository) { ['fake/img/path'] }.ordered

          expect(fs).to receive(:copy_including_intermediate_dirs).
              with('fake/img/path', section.path_to_repository, formatted_dir).ordered

          expect(fs).to receive(:copy_contents).
              with(formatted_dir, Pathname('output/master_middleman/source/go-here-please')).ordered

          DitaPreprocessor.new(dita_formatter,
            fs,
            instance_double('Bookbinder::DitaCommandCreator', convert_to_html_command: nil),
            instance_double('Bookbinder::Sheller', run_command: double('success').as_null_object)).
            preprocess([section], output_locations, options: [], output_streams: {}, random_key: 'thing')
        end
      end

      context "for dita sections with a ditamap" do
        it "formats the html for each dita section and copies files into the middleman source directory" do
          dita_formatter = instance_double('Bookbinder::DitaHtmlToMiddlemanFormatter',
            format_subnav: double('subnav').as_null_object)
          fs = instance_double('Bookbinder::LocalFilesystemAccessor', read: double('subnav template'), write: nil)
          stub_const('Bookbinder::Preprocessing::DitaPreprocessor::ACCEPTED_IMAGE_FORMATS', ['img-format'])

          output_locations = OutputLocations.new(context_dir: ".")
          section = Section.new('path-to-repository',
              'full/repo-name',
              nil,
              'subnav-template',
              nil,
              {'ditamap_location' => 'fake-ditamap'})

          formatted_dir = output_locations.formatted_dir.join(section.destination_directory)

          expect(dita_formatter).to receive(:format_html).
              with(output_locations.html_from_preprocessing_dir.join(section.destination_directory),
                formatted_dir).ordered

          expect(fs).to receive(:find_files_with_ext).
              with('img-format', section.path_to_repository) { ['fake/img/path'] }.ordered

          expect(fs).to receive(:copy_including_intermediate_dirs).
              with('fake/img/path', section.path_to_repository, formatted_dir).ordered

          expect(fs).to receive(:copy_contents).
              with(formatted_dir, Pathname('output/master_middleman/source/repo-name')).ordered

          DitaPreprocessor.new(dita_formatter,
            fs,
            instance_double('Bookbinder::DitaCommandCreator', convert_to_html_command: nil),
            instance_double('Bookbinder::Sheller', run_command: double('success').as_null_object)).
            preprocess([section], output_locations, options: [], output_streams: {})
        end

        it "runs the dita command and raises an exception on failure" do
          command_creator = instance_double('Bookbinder::DitaCommandCreator')
          sheller = instance_double('Bookbinder::Sheller')

          command = double('do-what-we-tell-you-to-do')

          output_locations = OutputLocations.new(context_dir: ".")

          section = Section.new(
            'path-to-repository',
            'full-name',
            'go-here-please',
            'subnav-template',
            nil,
            {'ditamap_location' => 'something'}
          )

          allow(command_creator).to receive(:convert_to_html_command).
              with(section,
                   dita_flags: nil,
                   write_to: Pathname('output/preprocessing/html_from_preprocessing/go-here-please')) { command }

          expect(sheller).to receive(:run_command).with(command, { good: 'here' }) { double('failure', success?: false) }

          expect{
            DitaPreprocessor.new(double('formatter'), double('fs'), command_creator, sheller).
              preprocess([section],
                         output_locations,
                         output_streams: { good: 'here' })
          }.to raise_error(RuntimeError)
        end

        it "passes dita options to the command creator" do
          command_creator = instance_double('Bookbinder::CommandCreator')
          dita_options = 'fake-option=some-thing other-fake=other-thing'

          expect(command_creator).to receive(:convert_to_html_command).
              with(anything, dita_flags: dita_options, write_to: anything)

          DitaPreprocessor.new(
            double('dita formatter').as_null_object,
            double('fs').as_null_object,
            command_creator,
            double('sheller').as_null_object
          ).preprocess(
            [Section.new('path-to-repository',
                'full-name',
                'go-here-please',
                'subnav-template',
                nil,
                {'ditamap_location' => 'fake-ditamap'})],
            OutputLocations.new(context_dir: "."),
            options: ["--dita-flags=#{dita_options}"]
          )
        end
      end

      describe "generating a subnav" do
        context "for dita sections with multiple ditamaps" do
          it "generates a json props file for each ditamap" do
            fs = instance_double('Bookbinder::LocalFilesystemAccessor', find_files_with_ext: nil, copy_including_intermediate_dirs: nil, copy_contents: nil)
            dita_formatter = instance_double('Bookbinder::DitaHtmlToMiddlemanFormatter', format_html: nil)

            section_one = Section.new('path-to-repository',
                                      'full-name',
                                      'dir-one',
                                      'subnav-template-one',
                                      nil,
                                      {'ditamap_location' => 'fake-ditamap-one'})

            section_two = Section.new('path-to-repository',
                                      'full-name',
                                      'dir-two',
                                      'subnav-template-two',
                                      nil,
                                      {'ditamap_location' => 'fake-ditamap-two'})

            output_locations = OutputLocations.new(context_dir: '.')

            it_generates_a_custom_subnav_for(section_one, fs, dita_formatter, output_locations)
            it_generates_a_custom_subnav_for(section_two, fs, dita_formatter, output_locations)

            DitaPreprocessor.new(
              dita_formatter,
              fs,
              double('command creator').as_null_object,
              double('sheller').as_null_object
            ).preprocess(
              [section_one, section_two],
              output_locations
            )
          end

          def it_generates_a_custom_subnav_for(section, fs, dita_formatter, output_locations)
            subnav = SubnavTemplate.new('subnav text', 'some json links')

            template_path = output_locations.source_for_site_generator.join('subnavs', '_dita_subnav_template.erb')
            expect(fs).to receive(:read).with(template_path) { 'template text' }

            toc_page = File.join(output_locations.html_from_preprocessing_dir.join(section.destination_directory), 'index.html')
            expect(fs).to receive(:read).with(toc_page) { 'toc text' }

            expect(dita_formatter).to receive(:format_subnav).
                with(section.destination_directory,
                  'template text',
                  "dita-subnav-props-#{section.destination_directory}.json",
                  'toc text') { subnav }

            expect(fs).to receive(:write).with(text: subnav.json_links,
                to: File.join(output_locations.subnavs_for_layout_dir,
                  "dita-subnav-props-#{section.destination_directory}.json")
              )

            expect(fs).to receive(:write).with(text: subnav.text,
                to: File.join(output_locations.subnavs_for_layout_dir,
                  "#{section.subnav_template}.erb")
              )
          end
        end
      end
    end
  end
end
