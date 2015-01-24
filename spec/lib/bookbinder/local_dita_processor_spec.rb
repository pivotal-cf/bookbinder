require_relative '../../../lib/bookbinder/local_dita_processor'
require_relative '../../../lib/bookbinder/dita_section'

module Bookbinder
  describe LocalDitaProcessor do
    describe 'processing sections' do
      it 'returns the local paths of the processed dita' do
        shell = double('shell_out')
        path_to_dita_ant_script = '/path/to/dita/ant/script.xml'
        processed_dita_location = '/path/to/processed/dita'
        dita_sections = [
            DitaSection.new('/local/path/to/repo', 'path/to/map.ditamap', 'org/foo', nil, 'boo')
        ]

        allow(shell).to receive(:run_command)
        dita_processor = LocalDitaProcessor.new(shell, path_to_dita_ant_script)
        processed_dita_paths = dita_processor.process(dita_sections, to: processed_dita_location)

        expect(processed_dita_paths).to eq ['/path/to/processed/dita/boo']
      end

      it 'runs the dita-processing library against the given ditamap locations' do
        shell = double('shell_out')
        path_to_dita_ant_script = '/path/to/dita/ant/script.xml'
        processed_dita_location = '/path/to/processed/dita'
        dita_sections = [
            DitaSection.new('/local/path/to/repo', 'path/to/map.ditamap', 'org/foo', nil, 'boo')
        ]

        dita_processor = LocalDitaProcessor.new(shell, path_to_dita_ant_script)
        expect(shell).to receive(:run_command)
                         .with('ant -f /path/to/dita/ant/script.xml ' +
                                '-Dditamap_location=/local/path/to/repo/path/to/map.ditamap ' +
                                '-Dout_dir=/path/to/processed/dita/boo', false)
        dita_processor.process(dita_sections, to: processed_dita_location)
      end
    end
  end
end