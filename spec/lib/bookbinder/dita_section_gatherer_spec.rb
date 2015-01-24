require_relative '../../../lib/bookbinder/dita_section_gatherer'
require_relative '../../../lib/bookbinder/dita_section'

module Bookbinder
  describe DitaSectionGatherer do
    describe 'gathering dita sections' do

      it 'clones the specified repos' do
        version_control_system = double('version_control_system')
        dita_section_gatherer = DitaSectionGatherer.new(version_control_system)
        dita_sections = [DitaSection.new(nil, '.ditamap', 'org/dita-repo', nil, 'dita-repo')]
        tmp_dir = 'output/tmpdir'

        expect(version_control_system).to receive(:clone).with('git@github.com:org/dita-repo',
                                                               'dita-repo',
                                                               path: tmp_dir)

        dita_section_gatherer.gather(dita_sections, to: tmp_dir)
      end

      it 'returns new sections with identical properties and the new path to the local repo' do
        version_control_system = double('version_control_system')
        dita_section_gatherer = DitaSectionGatherer.new(version_control_system)
        dita_sections = [DitaSection.new(nil, '.ditamap', 'org/dita-repo', nil, 'dita-repo')]
        tmp_dir = 'output/tmpdir'

        expected_dita_sections = [
            DitaSection.new('output/tmpdir/dita-repo',
                            '.ditamap',
                            'org/dita-repo',
                            nil,
                            'dita-repo')
        ]

        allow(version_control_system).to receive(:clone)
        expect(dita_section_gatherer.gather(dita_sections, to: tmp_dir)).to eq expected_dita_sections
      end
    end
  end
end