require_relative '../../../../lib/bookbinder/config/section_config'
require_relative '../../../../lib/bookbinder/preprocessing/dita_html_preprocessor'
require_relative '../../../../lib/bookbinder/values/output_locations'
require_relative '../../../../lib/bookbinder/values/section'
require_relative '../../../../lib/bookbinder/subnav/navigation_entries_from_html_toc'
require_relative '../../../../lib/bookbinder/local_filesystem_accessor'
require_relative '../../../../lib/bookbinder/dita_html_for_middleman_formatter'
require_relative '../../../../lib/bookbinder/preprocessing/dita_html_preprocessor'
require_relative '../../../../lib/bookbinder/subnav/subnav_generator'
require_relative '../../../../lib/bookbinder/subnav/subnav_generator_factory'
require_relative '../../../../lib/bookbinder/dita_command_creator'
require_relative '../../../../lib/bookbinder/sheller'

module Bookbinder
  module Preprocessing
    describe DitaHTMLPreprocessor do
      describe 'applicable to' do
        it "is true for sections configured with a default dita subnav" do
          expect(DitaHTMLPreprocessor.new(
              double('fs'),
              double('subnav gen factory'),
              double('formatter'),
              double('command creator'),
              double('sheller'))).
            to be_applicable_to(Config::SectionConfig.new('subnav_template' => 'dita_subnav'))
        end

        it "is true for sections configured with a non-default dita subnav" do
          expect(DitaHTMLPreprocessor.new(
              double('fs'),
              double('subnav gen factory'),
              double('formatter'),
              double('command creator'),
              double('sheller'))).
            to be_applicable_to(Config::SectionConfig.new('subnav_template' => 'dita_subnav_100'))
        end

        it "is false for anything else" do
          expect(DitaHTMLPreprocessor.new(
              double('fs'),
              double('subnav gen factory'),
              double('formatter'),
              double('command creator'),
              double('sheller'))).
            not_to be_applicable_to(Config::SectionConfig.new('subnav_template' => 'something_else'))
        end
      end

      context "for dita sections with a ditamap" do
        it "generates a subnav for each section with ditamap" do
          output_locations = OutputLocations.new(context_dir: ".")
          sections = [
            Section.new('path-to-repository',
              'full-name',
              'nav-here-please',
              'subnav-template',
              nil,
              {'ditamap_location' => 'fake-ditamap'}),
            Section.new('path-to-repository',
              'full-name',
              'go-here-please',
              'subnav-template',
              nil,
              {})
          ]

          subnav_generator = instance_double(Bookbinder::Subnav::SubnavGenerator)
          subnav_generator_factory = instance_double(Bookbinder::Subnav::SubnavGeneratorFactory)

          expect(subnav_generator_factory).to receive(:produce).with(instance_of(Bookbinder::Subnav::NavigationEntriesFromHtmlToc)) { subnav_generator }
          expect(subnav_generator).to receive(:generate).with(sections[0])

          DitaHTMLPreprocessor.new(double('fs').as_null_object,
            subnav_generator_factory,
            double('dita formatter').as_null_object,
            double('dita command creator').as_null_object,
            double('sheller').as_null_object
          ).preprocess(sections, output_locations)
        end

        it "runs the dita command and raises an exception on failure" do
          command_creator = instance_double(Bookbinder::DitaCommandCreator)
          sheller = instance_double(Bookbinder::Sheller)

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
            DitaHTMLPreprocessor.new(double('fs'), double('subnav generator'), double('formatter'), command_creator, sheller).
              preprocess([section],
                         output_locations,
                         output_streams: { good: 'here' })
          }.to raise_error(RuntimeError)
        end

        it "passes dita options to the command creator" do
          command_creator = instance_double(Bookbinder::DitaCommandCreator)
          dita_options = 'fake-option=some-thing other-fake=other-thing'

          expect(command_creator).to receive(:convert_to_html_command).
              with(anything, dita_flags: dita_options, write_to: anything)

          DitaHTMLPreprocessor.new(
            double('fs').as_null_object,
            double('subnav generator').as_null_object,
            double('dita formatter').as_null_object,
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
            options: { dita_flags: dita_options }
          )
        end
      end

      it "copies html and images for each section and its dependent sections" do
        output_locations = OutputLocations.new(context_dir: ".")
        sections = [
          Section.new('path-to-repository',
            'full-name',
            'nav-here-please',
            'subnav-template',
            nil,
            {'ditamap_location' => 'fake-ditamap'}),
          Section.new('path-to-repository',
            'full-name',
            'go-here-please',
            'subnav-template',
            nil,
            {})
        ]

        nav_formatted_dir = output_locations.formatted_dir.join('nav-here-please')
        nonnav_formatted_dir = output_locations.formatted_dir.join('go-here-please')

        fs = instance_double(Bookbinder::LocalFilesystemAccessor)
        dita_formatter = instance_double(Bookbinder::DitaHtmlForMiddlemanFormatter)
        stub_const('Bookbinder::Preprocessing::DitaHTMLPreprocessor::ACCEPTED_IMAGE_FORMATS', ['img-format'])

        expect(dita_formatter).to receive(:format_html).
            with(output_locations.html_from_preprocessing_dir.join('nav-here-please'),
                 nav_formatted_dir)

        expect(fs).to receive(:find_files_with_ext).
            with('img-format', sections[0].path_to_repo_dir) { ['fake/img/path'] }

        expect(fs).to receive(:copy_including_intermediate_dirs).
            with('fake/img/path', sections[0].path_to_repo_dir, nav_formatted_dir)

        expect(fs).to receive(:copy_contents).
            with(nav_formatted_dir, Pathname('output/master_middleman/source/nav-here-please'))

        expect(dita_formatter).to receive(:format_html).
            with(output_locations.html_from_preprocessing_dir.join('go-here-please'),
              nonnav_formatted_dir)

        expect(fs).to receive(:find_files_with_ext).
            with('img-format', sections[1].path_to_repo_dir) { ['fake/img/path'] }

        expect(fs).to receive(:copy_including_intermediate_dirs).
            with('fake/img/path', sections[1].path_to_repo_dir, nonnav_formatted_dir)

        expect(fs).to receive(:copy_contents).
            with(nonnav_formatted_dir, Pathname('output/master_middleman/source/go-here-please'))

        DitaHTMLPreprocessor.new(fs,
          double('subnav generator factory').as_null_object,
          dita_formatter,
          double('dita command creator').as_null_object,
          double('sheller').as_null_object
        ).preprocess(sections, output_locations)
      end

    end
  end
end
