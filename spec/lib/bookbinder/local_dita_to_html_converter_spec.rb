require_relative '../../../lib/bookbinder/configuration'
require_relative '../../../lib/bookbinder/values/dita_section'
require_relative '../../../lib/bookbinder/local_dita_to_html_converter'
require_relative '../../../lib/bookbinder/sheller'

module Bookbinder
  describe LocalDitaToHtmlConverter do
    describe 'processing sections' do
      let(:path_to_dita_ot_library) { '/path/to/dita/ot' }

      it 'runs the dita-processing library against the given ditamap locations' do
        shell = double('shell_out')
        processed_dita_location = '/path/to/processed/dita/boo'
        dita_section = DitaSection.new('/local/path/to/repo', 'path/to/map.ditamap', 'path/to/val.ditaval', 'org/foo', nil, 'boo')

        dita_converter = LocalDitaToHtmlConverter.new(shell, path_to_dita_ot_library)
        expect(shell).to receive(:run_command)
                         .with("export CLASSPATH=#{classpath}; " +
                               'ant -f /path/to/dita/ot ' +
                               "-Dbasedir='/' " +
                               '-Doutput.dir=/path/to/processed/dita/boo ' +
                               "-Dtranstype='tocjs' " +
                               "-Ddita.temp.dir='/tmp/bookbinder_dita' " +
                               "-Dgenerate.copy.outer='2' " +
                               '-Dargs.input=/local/path/to/repo/path/to/map.ditamap ' +
                               '-Dargs.filter=/local/path/to/repo/path/to/val.ditaval '
                         )
        dita_converter.convert_to_html(dita_section, write_to: processed_dita_location)
      end

      context 'when no ditaval file is provided' do
        it 'does not apply the filters' do
          shell = double('shell_out')
          processed_dita_location = '/path/to/processed/dita/boo'

          dita_section = DitaSection.new('/local/path/to/repo', 'path/to/map.ditamap', nil, 'org/foo', nil, 'boo')

          dita_converter = LocalDitaToHtmlConverter.new(shell, path_to_dita_ot_library)
          expect(shell).to receive(:run_command)
                           .with("export CLASSPATH=#{classpath}; " +
                                     'ant -f /path/to/dita/ot ' +
                                     "-Dbasedir='/' " +
                                     '-Doutput.dir=/path/to/processed/dita/boo ' +
                                     "-Dtranstype='tocjs' " +
                                     "-Ddita.temp.dir='/tmp/bookbinder_dita' " +
                                     "-Dgenerate.copy.outer='2' " +
                                     '-Dargs.input=/local/path/to/repo/path/to/map.ditamap '
                           )
          dita_converter.convert_to_html(dita_section, write_to: processed_dita_location)
        end
      end

      context 'when running the dita processing library fails' do
        it 're-raises with a helpful message' do
          shell = double('shell_out')
          processed_dita_location = '/path/to/processed/dita'
          dita_section = DitaSection.new('/local/path/to/repo',
                                         'path/to/map.ditamap',
                                         nil,
                                         'org/foo',
                                         nil,
                                         'boo')

          allow(shell).to receive(:run_command).and_raise Sheller::ShelloutFailure

          dita_converter = LocalDitaToHtmlConverter.new(shell, path_to_dita_ot_library)
          expect { dita_converter.convert_to_html(dita_section, write_to: processed_dita_location) }.
              to raise_error(LocalDitaToHtmlConverter::DitaToHtmlLibraryFailure,
                             'The DITA-to-HTML conversion failed. Please check that you have specified the ' +
                             'path to your DITA-OT library in the ENV, that your DITA-specific keys/values in ' +
                             'config.yml are set, and that your DITA toolkit is correctly configured.')
        end
      end

      let(:classpath) do
        '/path/to/dita/ot/lib/xercesImpl.jar:' +
        '/path/to/dita/ot/lib/xml-apis.jar:' +
        '/path/to/dita/ot/lib/resolver.jar:' +
        '/path/to/dita/ot/lib/commons-codec-1.4.jar:' +
        '/path/to/dita/ot/lib/icu4j.jar:' +
        '/path/to/dita/ot/lib/saxon/saxon9-dom.jar:' +
        '/path/to/dita/ot/lib/saxon/saxon9.jar:target/classes:' +
        '/path/to/dita/ot:' +
        '/path/to/dita/ot/lib/:' +
        '/path/to/dita/ot/lib/dost.jar'
      end
    end
  end
end
