require_relative '../../../lib/bookbinder/configuration'
require_relative '../../../lib/bookbinder/values/dita_section'
require_relative '../../../lib/bookbinder/dita_command'

module Bookbinder
  describe DitaCommand do
    let(:path_to_dita_ot_library) { '/path/to/dita/ot' }

    it 'creates the command that will run the dita-processing library' do
      shell = double('shell_out')
      processed_dita_location = '/path/to/processed/dita/boo'
      dita_section = DitaSection.new('/local/path/to/repo', 'path/to/map.ditamap', 'path/to/val.ditaval', 'org/foo', nil, 'boo')

      dita_converter = DitaCommand.new(shell, path_to_dita_ot_library)

      expect(dita_converter.convert_to_html(dita_section, write_to: processed_dita_location)).
        to eq("export CLASSPATH=#{classpath}; " +
              'ant -f /path/to/dita/ot ' +
              "-Dbasedir='/' " +
              '-Doutput.dir=/path/to/processed/dita/boo ' +
              "-Dtranstype='tocjs' " +
              "-Ddita.temp.dir='/tmp/bookbinder_dita' " +
              "-Dgenerate.copy.outer='2' " +
              '-Dargs.input=/local/path/to/repo/path/to/map.ditamap ' +
              '-Dargs.filter=/local/path/to/repo/path/to/val.ditaval '
             )
    end

    context 'when no ditaval file is provided' do
      it 'does not apply the filters' do
        shell = double('shell_out')
        processed_dita_location = '/path/to/processed/dita/boo'

        dita_section = DitaSection.new('/local/path/to/repo', 'path/to/map.ditamap', nil, 'org/foo', nil, 'boo')

        dita_converter = DitaCommand.new(shell, path_to_dita_ot_library)
        expect(dita_converter.convert_to_html(dita_section, write_to: processed_dita_location)).
          to eq("export CLASSPATH=#{classpath}; " +
                'ant -f /path/to/dita/ot ' +
                  "-Dbasedir='/' " +
                  '-Doutput.dir=/path/to/processed/dita/boo ' +
                  "-Dtranstype='tocjs' " +
                  "-Ddita.temp.dir='/tmp/bookbinder_dita' " +
                  "-Dgenerate.copy.outer='2' " +
                  '-Dargs.input=/local/path/to/repo/path/to/map.ditamap ')
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
