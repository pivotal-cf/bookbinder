require_relative '../../../lib/bookbinder/local_dita_processor'
require_relative '../../../lib/bookbinder/dita_section'
require_relative '../../../lib/bookbinder/sheller'

module Bookbinder
  describe LocalDitaProcessor do
    describe 'processing sections' do
      it 'returns the local paths of the processed dita' do
        shell = double('shell_out')
        path_to_dita_ot_library = '/path/to/dita_ot'
        processed_dita_location = '/path/to/processed/dita'
        dita_sections = [
            DitaSection.new('/local/path/to/repo', 'path/to/map.ditamap', 'org/foo', nil, 'boo')
        ]

        allow(shell).to receive(:run_command)
        dita_processor = LocalDitaProcessor.new(shell, path_to_dita_ot_library)
        processed_dita_paths = dita_processor.process(dita_sections, to: processed_dita_location)

        expect(processed_dita_paths).to eq ['/path/to/processed/dita/boo']
      end

      it 'runs the dita-processing library against the given ditamap locations' do
        shell = double('shell_out')
        path_to_dita_ot_library = '/path/to/dita/ot'
        processed_dita_location = '/path/to/processed/dita'
        classpath = '/path/to/dita/ot/lib/xercesImpl.jar:' +
                    '/path/to/dita/ot/lib/xml-apis.jar:' +
                    '/path/to/dita/ot/lib/resolver.jar:' +
                    '/path/to/dita/ot/lib/commons-codec-1.4.jar:$DITA_DIR/lib/icu4j.jar:' +
                    '/path/to/dita/ot/lib/saxon/saxon9-dom.jar:' +
                    '/path/to/dita/ot/lib/saxon/saxon9.jar:target/classes:' +
                    '/path/to/dita/ot:' +
                    '/path/to/dita/ot/lib/:' +
                    '/path/to/dita/ot/lib/dost.jar'

        dita_sections = [
            DitaSection.new('/local/path/to/repo', 'path/to/map.ditamap', 'org/foo', nil, 'boo')
        ]

        dita_processor = LocalDitaProcessor.new(shell, path_to_dita_ot_library)
        expect(shell).to receive(:run_command)
                         .with('export DITA_DIR=/path/to/dita/ot; ' +
                               "export CLASSPATH=#{classpath}; " +
                               'ant -f /path/to/dita/ot ' +
                               "-Dbasedir='/' " +
                               '-Doutput.dir=/path/to/processed/dita/boo ' +
                               "-Dtranstype='htmlhelp' " +
                               '-Dargs.input=/local/path/to/repo/path/to/map.ditamap')
        dita_processor.process(dita_sections, to: processed_dita_location)
      end

      context 'when running the dita processing library fails' do
        it 're-raises with a helpful message' do
          shell = double('shell_out')
          path_to_dita_ot_library = '/path/to/dita_ot'
          processed_dita_location = '/path/to/processed/dita'
          dita_sections = [
              DitaSection.new('/local/path/to/repo', 'path/to/map.ditamap', 'org/foo', nil, 'boo')
          ]

          allow(shell).to receive(:run_command).and_raise Sheller::ShelloutFailure

          dita_processor = LocalDitaProcessor.new(shell, path_to_dita_ot_library)
          expect { dita_processor.process(dita_sections, to: processed_dita_location) }.
              to raise_error(LocalDitaProcessor::DitaLibraryFailure,
                             'The DITA-to-HTML conversion failed. Please check your DITA-specific keys/values in ' +
                             'config.yml and ensure that your DITA toolkit is correctly configured.')
        end
      end
    end
  end
end