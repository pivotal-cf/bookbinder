require_relative '../../../lib/bookbinder/configuration'
require_relative '../../../lib/bookbinder/values/dita_section'
require_relative '../../../lib/bookbinder/dita_command_creator'

module Bookbinder
  describe DitaCommandCreator do
    let(:path_to_dita_ot_library) { '/path/to/dita/ot' }

    it 'includes default flags in the command that will run the dita-processing library' do
      processed_dita_location = '/path/to/processed/dita/boo'
      dita_section = DitaSection.new('/local/path/to/repo',
                                     'path/to/map.ditamap',
                                     'path/to/val.ditaval',
                                     'org/foo',
                                     nil,
                                     'boo')

      command_creator = DitaCommandCreator.new(path_to_dita_ot_library)

      expect(command_creator.convert_to_html_command(dita_section, write_to: processed_dita_location)).
        to eq("export CLASSPATH=#{classpath}; " +
              'ant -f /path/to/dita/ot ' +
              "-Doutput.dir='/path/to/processed/dita/boo' " +
              "-Dargs.input='/local/path/to/repo/path/to/map.ditamap' " +
              "-Dargs.filter='/local/path/to/repo/path/to/val.ditaval' " +
              "-Dbasedir='/' " +
              "-Dtranstype='tocjs' " +
              "-Ddita.temp.dir='/tmp/bookbinder_dita' " +
              "-Dgenerate.copy.outer='2' " +
              "-Douter.control='warn' "
             )
    end

    context 'when no ditaval file is provided' do
      it 'does not apply the filters' do
        processed_dita_location = '/path/to/processed/dita/boo'
        dita_section = DitaSection.new('/local/path/to/repo',
                                       'path/to/map.ditamap',
                                       nil,
                                       'org/foo',
                                       nil,
                                       'boo')

        command_creator = DitaCommandCreator.new(path_to_dita_ot_library)
        expect(command_creator.convert_to_html_command(dita_section, write_to: processed_dita_location)).
          to eq(default_command)
      end
    end

    context 'when optional DITA flags are passed in' do
      it 'adds those flags to the default flags' do
        command_creator = DitaCommandCreator.new(path_to_dita_ot_library)
        processed_dita_location = '/path/to/processed/dita/boo'
        dita_section = DitaSection.new('/local/path/to/repo',
                                       'path/to/map.ditamap',
                                       nil,
                                       'org/foo',
                                       nil,
                                       'boo')

        expect(command_creator.convert_to_html_command(
                   dita_section,
                   dita_flags: "clean.temp=obv",
                   write_to: processed_dita_location)
        ).to eq(default_command +
                "-Dclean.temp='obv' "
             )
      end

      context 'when a passed flag overlaps with a default flag' do
        it 'prefers the passed flag' do
          command_creator = DitaCommandCreator.new(path_to_dita_ot_library)
          processed_dita_location = '/path/to/processed/dita/boo'
          dita_section = DitaSection.new('/local/path/to/repo',
                                         'path/to/map.ditamap',
                                         nil,
                                         'org/foo',
                                         nil,
                                         'boo')

          expect(command_creator.convert_to_html_command(
                     dita_section,
                     dita_flags: "clean.temp=obv dita.temp.dir=hey/some/new/dir",
                     write_to: processed_dita_location)
          ).to eq("export CLASSPATH=#{classpath}; " +
                      'ant -f /path/to/dita/ot ' +
                      "-Doutput.dir='/path/to/processed/dita/boo' " +
                      "-Dargs.input='/local/path/to/repo/path/to/map.ditamap' " +
                      "-Dargs.filter='' " +
                      "-Dbasedir='/' " +
                      "-Dtranstype='tocjs' " +
                      "-Ddita.temp.dir='hey/some/new/dir' " +
                      "-Dgenerate.copy.outer='2' " +
                      "-Douter.control='warn' " +
                      "-Dclean.temp='obv' "
               )
        end
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

    let(:default_command) do
      "export CLASSPATH=#{classpath}; " +
      'ant -f /path/to/dita/ot ' +
      "-Doutput.dir='/path/to/processed/dita/boo' " +
      "-Dargs.input='/local/path/to/repo/path/to/map.ditamap' " +
      "-Dargs.filter='' " +
      "-Dbasedir='/' " +
      "-Dtranstype='tocjs' " +
      "-Ddita.temp.dir='/tmp/bookbinder_dita' " +
      "-Dgenerate.copy.outer='2' " +
      "-Douter.control='warn' "
    end
  end
end
