require_relative '../../../lib/bookbinder/local_dita_section_gatherer'
require_relative '../../../lib/bookbinder/values/dita_section'
require_relative '../../../lib/bookbinder/values/output_locations'

module Bookbinder
  describe LocalDitaSectionGatherer do
    it 'creates DitaSections which specify where the sections are on the local file system' do
      output_locations = OutputLocations.new(local_repo_dir: 'local')
      local_dita_section_gatherer = LocalDitaSectionGatherer.new(output_locations)

      dita_section_from_config = [
          {'repository' => {
              'name' => 'fantastic/dogs-repo',
              'ref' => 'dog-sha'},
           'directory' => 'dogs',
           'ditamap_location' => 'dita-section.ditamap'},
          {'repository' => {
              'name' => 'fantastic/my-docs-repo',
              'ref' => 'some-sha'},
           'directory' => 'foods/sweet',
           'ditamap_location' => 'dita-section-two.ditamap'},
      ]

      actual_sections = local_dita_section_gatherer.gather(dita_section_from_config)
      expected_sections = [
          DitaSection.new(Pathname('local/dogs'),
                          'dita-section.ditamap',
                          'fantastic/dogs-repo',
                          'dog-sha',
                          'dogs',
                          output_locations),
          DitaSection.new(Pathname('local/foods/sweet'),
                          'dita-section-two.ditamap',
                          'fantastic/my-docs-repo',
                          'some-sha',
                          'foods/sweet',
                          output_locations)
      ]

      expect(actual_sections).to eq expected_sections
    end
  end
end
