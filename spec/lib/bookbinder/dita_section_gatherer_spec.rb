require_relative '../../../lib/bookbinder/dita_section_gatherer'
require_relative '../../../lib/bookbinder/dita_section'
require_relative '../../../lib/bookbinder/bookbinder_logger'

module Bookbinder
  describe DitaSectionGatherer do
    describe 'gathering dita sections' do

      it 'clones the specified repos' do
        view_updater = double('view_updater')
        version_control_system = double('version_control_system')
        dita_section_gatherer = DitaSectionGatherer.new(version_control_system, view_updater)
        dita_sections = [DitaSection.new(nil, '.ditamap', 'org/dita-repo', nil, 'dita-repo')]
        tmp_dir = 'output/tmpdir'

        allow(view_updater).to receive(:log)
        expect(version_control_system).to receive(:clone).with('git@github.com:org/dita-repo',
                                                               'dita-repo',
                                                               path: tmp_dir)

        dita_section_gatherer.gather(dita_sections, to: tmp_dir)
      end

      it 'returns new sections with identical properties and the new path to the local repo' do
        view_updater = double('view_updater')
        version_control_system = double('version_control_system')
        dita_section_gatherer = DitaSectionGatherer.new(version_control_system, view_updater)
        dita_sections = [DitaSection.new(nil, '.ditamap', 'org/dita-repo', nil, 'dita-repo')]
        tmp_dir = 'output/tmpdir'

        expected_dita_sections = [
            DitaSection.new('output/tmpdir/dita-repo',
                            '.ditamap',
                            'org/dita-repo',
                            nil,
                            'dita-repo')
        ]

        allow(view_updater).to receive(:log)
        allow(version_control_system).to receive(:clone)
        expect(dita_section_gatherer.gather(dita_sections, to: tmp_dir)).to eq expected_dita_sections
      end

      it 'updates the user on its progress' do
        version_control_system = double('version_control_system')
        view_updater = double('view_updater')
        dita_section_gatherer = DitaSectionGatherer.new(version_control_system, view_updater)
        dita_sections = [DitaSection.new(nil, '.ditamap', 'org/dita-repo', nil, 'dita-repo')]
        tmp_dir = 'output/tmpdir'

        allow(version_control_system).to receive(:clone)
        expect(view_updater).to receive(:log).with("Gathering \e[36morg/dita-repo\e[0m")

        dita_section_gatherer.gather(dita_sections, to: tmp_dir)
      end
    end
  end
end