require_relative '../../../lib/bookbinder/remote_dita_section_gatherer'
require_relative '../../../lib/bookbinder/values/output_locations'

module Bookbinder
  describe RemoteDitaSectionGatherer do
    describe 'gathering dita sections' do
      it 'clones the specified repos' do
        dita_section_from_config = [
            {'repository' => {
                'name' => 'fantastic/dita-repo',
                'ref' => 'dog-sha'},
             'directory' => 'dogs',
             'ditamap_location' => 'dita-section.ditamap',
             'ditaval_location' => 'dita-val.ditaval' },
            {'repository' => {
                'name' => 'cool/dita-repo'},
             'directory' => 'foods/sweet'},
        ]

        view_updater = double('view_updater')
        version_control_system = double('version_control_system')
        dita_section_gatherer = RemoteDitaSectionGatherer.new(
          version_control_system,
          view_updater,
          OutputLocations.new(context_dir: 'context_dir')
        )

        allow(view_updater).to receive(:log)
        path = Pathname('context_dir/output/preprocessing/sections')
        expect(version_control_system).to receive(:clone)
                                          .with('git@github.com:fantastic/dita-repo',
                                                'dogs',
                                                path: path,
                                                checkout: 'dog-sha')

        expect(version_control_system).to receive(:clone)
                                          .with('git@github.com:cool/dita-repo',
                                                'foods/sweet',
                                                path: path,
                                                checkout: 'master')

        dita_section_gatherer.gather(dita_section_from_config)
      end

      it 'returns new sections with identical properties and the new path to the local repo' do
        dita_section_from_config = [
            {'repository' => {
                'name' => 'fantastic/dogs-repo',
                'ref' => 'dog-sha'},
             'directory' => 'dogs',
             'ditamap_location' => 'dita-section.ditamap',
             'ditaval_location' => 'dita-val.ditaval' },
            {'repository' => {
                'name' => 'cool/dogs-repo'},
             'directory' => 'foods/sweet'},
        ]

        view_updater = double('view_updater')
        version_control_system = double('version_control_system')
        output_locations = OutputLocations.new(context_dir: 'context_dir')
        dita_section_gatherer = RemoteDitaSectionGatherer.new(version_control_system,
                                                              view_updater,
                                                              output_locations)
        expected_dita_sections = [
          Section.new(Pathname('context_dir/output/preprocessing/sections/dogs'),
                      'fantastic/dogs-repo',
                      copied = true,
                      output_locations.cloned_preprocessing_dir,
                      dir_name = 'dogs',
                      'dita_subnav',
                      'ditamap_location' => 'dita-section.ditamap',
                      'ditaval_location' => 'dita-val.ditaval'),
          Section.new(Pathname('context_dir/output/preprocessing/sections/foods/sweet'),
                      'cool/dogs-repo',
                      copied = true,
                      output_locations.cloned_preprocessing_dir,
                      'foods/sweet',
                      'dita_subnav',
                      'ditamap_location' => nil,
                      'ditaval_location' => nil)
        ]

        allow(view_updater).to receive(:log)
        allow(version_control_system).to receive(:clone)
        expect(dita_section_gatherer.gather(dita_section_from_config)[0]).to eq(expected_dita_sections[0])
        expect(dita_section_gatherer.gather(dita_section_from_config)[1]).to eq(expected_dita_sections[1])
      end

      it 'updates the user on its progress' do
        dita_section_from_config = [
            {'repository' => {
                'name' => 'fantastic/dita-repo',
                'ref' => 'dog-sha'},
             'directory' => 'dogs',
             'ditamap_location' => 'dita-section.ditamap',
             'ditaval_location' => 'dita-val.ditaval' },
            {'repository' => {
                'name' => 'cool/dita-repo',
                'ref' => 'some-sha'},
             'directory' => 'foods/sweet'},
        ]

        version_control_system = double('version_control_system')
        view_updater = double('view_updater')
        dita_section_gatherer = RemoteDitaSectionGatherer.new(
          version_control_system,
          view_updater,
          OutputLocations.new(context_dir: 'context_dir')
        )
        allow(version_control_system).to receive(:clone)
        expect(view_updater).to receive(:log).with("Gathering \e[36mfantastic/dita-repo\e[0m")
        expect(view_updater).to receive(:log).with("Gathering \e[36mcool/dita-repo\e[0m")

        dita_section_gatherer.gather(dita_section_from_config)
      end
    end
  end
end
