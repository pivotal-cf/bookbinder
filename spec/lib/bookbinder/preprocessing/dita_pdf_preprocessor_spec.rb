require_relative '../../../../lib/bookbinder/config/section_config'
require_relative '../../../../lib/bookbinder/preprocessing/dita_pdf_preprocessor'
require_relative '../../../../lib/bookbinder/dita_command_creator'
require_relative '../../../../lib/bookbinder/sheller'
require_relative '../../../../lib/bookbinder/values/output_locations'
require_relative '../../../../lib/bookbinder/values/section'
require_relative '../../../../lib/bookbinder/local_filesystem_accessor'


module Bookbinder
  module Preprocessing
    describe DitaPDFPreprocessor do
      describe 'applicable to' do
        it 'is true for sections with a pdf output filename' do
          expect(DitaPDFPreprocessor.new(
              double('fs'),
              double('command creator'),
              double('sheller'))).
            to be_applicable_to(Section.new(nil,nil,nil,nil,nil,nil,nil, nil, nil,'my-pdf-name.pdf'))
        end

        it 'is false for sections without a ditamap' do
          expect(DitaPDFPreprocessor.new(
              double('fs'),
              double('command creator'),
              double('sheller'))).
            not_to be_applicable_to(Section.new)
        end
      end

      describe 'preprocess' do
        it 'runs the dita command and raises an exception on failure' do
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

          allow(command_creator).to receive(:convert_to_pdf_command).
              with(section,
                dita_flags: nil,
                write_to: output_locations.pdf_from_preprocessing_dir) { command }

          expect(sheller).to receive(:run_command).with(command, { good: 'here' }) { double('failure', success?: false) }

          expect{
            DitaPDFPreprocessor.new(double('fs'), command_creator, sheller).
              preprocess([section],
                output_locations,
                output_streams: { good: 'here' })
          }.to raise_error(RuntimeError)
        end

        it 'passes dita options to the command creator' do
          command_creator = instance_double(Bookbinder::DitaCommandCreator)
          dita_options = 'fake-option=some-thing other-fake=other-thing'

          expect(command_creator).to receive(:convert_to_pdf_command).
              with(anything, dita_flags: dita_options, write_to: anything)

          DitaPDFPreprocessor.new(
            double('fs').as_null_object,
            command_creator,
            double('sheller').as_null_object
          ).preprocess(
            [Section.new('path-to-repository',
                'full-name',
                'go-here-please',
                'subnav-template',
                nil,
                {'ditamap_location' => 'fake-ditamap'},
                nil, nil, nil,
                'my-pdf-name.pdf')
            ],
            OutputLocations.new(context_dir: "."),
            options: { dita_flags: dita_options }
          )
        end

        it 'copies the pdf to the output filename in the artifacts directory' do
          output_locations = OutputLocations.new(context_dir: ".")
          fs = instance_double(LocalFilesystemAccessor)

          allow(Dir).to receive(:glob) { ['./my-first-pdf', './my-second-pdf'] }
          allow(File).to receive(:mtime).with('./my-first-pdf') { Time.now }
          allow(File).to receive(:mtime).with('./my-second-pdf') { Time.now }

          sheller = double('sheller')
          allow(sheller).to receive(:run_command) { double('success', success?: true) }

          destination = output_locations.pdf_artifact_dir.join('my-pdf-name.pdf')
          expect(fs).to receive(:copy_and_rename).with('./my-second-pdf', destination)

          DitaPDFPreprocessor.new(
            fs,
            instance_double(Bookbinder::DitaCommandCreator, convert_to_pdf_command: double('command')),
            sheller
          ).preprocess(
            [Section.new('path-to-repository',
                'full-name',
                'go-here-please',
                'subnav-template',
                nil,
                {'ditamap_location' => 'fake-ditamap'},
                nil, nil, nil,
                'my-pdf-name.pdf'
              )],
            output_locations,
            options: {}
          )
        end
      end
    end
  end
end
