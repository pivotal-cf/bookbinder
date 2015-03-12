require_relative '../../../lib/bookbinder/remote_dita_section_gatherer'

module Bookbinder
  describe RemoteDitaSectionGatherer do
    describe 'gathering dita sections' do
      it 'clones the specified repos' do
        dita_section_from_config = [
            {'repository' => {
                'name' => 'fantastic/dita-repo',
                'ref' => 'dog-sha'},
             'directory' => 'dogs',
             'ditamap_location' => 'dita-section.ditamap'},
            {'repository' => {
                'name' => 'cool/dita-repo',
                'ref' => 'some-sha'},
             'directory' => 'foods/sweet',
             'ditamap_location' => 'dita-section-two.ditamap'},
        ]

        view_updater = double('view_updater')
        version_control_system = double('version_control_system')
        dita_section_gatherer = RemoteDitaSectionGatherer.new(version_control_system,
                                                              view_updater,
                                                              'cloned_dita_dir',
                                                              nil)

        allow(view_updater).to receive(:log)
        expect(version_control_system).to receive(:clone)
                                          .with('git@github.com:fantastic/dita-repo',
                                                'dogs',
                                                path: 'cloned_dita_dir')

        expect(version_control_system).to receive(:clone)
                                          .with('git@github.com:cool/dita-repo',
                                                'foods/sweet',
                                                path: 'cloned_dita_dir')

        dita_section_gatherer.gather(dita_section_from_config)
      end

      it 'returns new sections with identical properties and the new path to the local repo' do
        dita_section_from_config = [
            {'repository' => {
                'name' => 'fantastic/dogs-repo',
                'ref' => 'dog-sha'},
             'directory' => 'dogs',
             'ditamap_location' => 'dita-section.ditamap'},
            {'repository' => {
                'name' => 'cool/dogs-repo',
                'ref' => 'some-sha'},
             'directory' => 'foods/sweet',
             'ditamap_location' => 'dita-section-two.ditamap'},
        ]

        view_updater = double('view_updater')
        version_control_system = double('version_control_system')
        dita_section_gatherer = RemoteDitaSectionGatherer.new(version_control_system,
                                                              view_updater,
                                                              'cloned_dita_dir',
                                                              nil)
        expected_dita_sections = [
            DitaSection.new('cloned_dita_dir/dogs',
                            'dita-section.ditamap',
                            'fantastic/dogs-repo',
                            'dog-sha',
                            'dogs',
                            nil),
            DitaSection.new('cloned_dita_dir/foods/sweet',
                            'dita-section-two.ditamap',
                            'cool/dogs-repo',
                            'some-sha',
                            'foods/sweet',
                            nil)
        ]

        allow(view_updater).to receive(:log)
        allow(version_control_system).to receive(:clone)
        expect(dita_section_gatherer.gather(dita_section_from_config)).to match_array expected_dita_sections
      end

      it 'updates the user on its progress' do
        dita_section_from_config = [
            {'repository' => {
                'name' => 'fantastic/dita-repo',
                'ref' => 'dog-sha'},
             'directory' => 'dogs',
             'ditamap_location' => 'dita-section.ditamap'},
            {'repository' => {
                'name' => 'cool/dita-repo',
                'ref' => 'some-sha'},
             'directory' => 'foods/sweet',
             'ditamap_location' => 'dita-section-two.ditamap'},
        ]

        version_control_system = double('version_control_system')
        view_updater = double('view_updater')
        dita_section_gatherer = RemoteDitaSectionGatherer.new(version_control_system,
                                                              view_updater,
                                                              'cloned_dita_dir',
                                                              nil)
        allow(version_control_system).to receive(:clone)
        expect(view_updater).to receive(:log).with("Gathering \e[36mfantastic/dita-repo\e[0m")
        expect(view_updater).to receive(:log).with("Gathering \e[36mcool/dita-repo\e[0m")

        dita_section_gatherer.gather(dita_section_from_config)
      end
    end
  end
end