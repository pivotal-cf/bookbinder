require_relative '../../../lib/bookbinder/local_dita_preprocessor'
require_relative '../../../lib/bookbinder/dita_section'

module Bookbinder
  describe LocalDitaPreprocessor do
    it 'converts, formats, provides a subnav, and copies the resulting DITA sections into the output directory' do
      dita_converter = double('dita_converter')
      dita_formatter = double('dita_formatter')
      fs_accessor = double('fs_accessor')
      allow(fs_accessor).to receive(:read).with('output/master_middleman/source/subnavs/_dita_subnav_template').and_return '<div>this is the dita subnav template</div>'
      allow(fs_accessor).to receive(:read).with('output/tmp/html_from_dita/my_dita_section/index.html').and_return '<a href="subnav/link">Link</a>'

      local_dita_preprocessor = LocalDitaPreprocessor.new(dita_converter, dita_formatter, fs_accessor)

      dita_section = DitaSection.new(nil, nil, nil, nil, 'my_dita_section')
      props_file_location = 'output/master_middleman/source/subnavs/my_dita_section-props.json'

      expect(dita_converter).to receive(:convert).with(dita_section, to: 'output/tmp/html_from_dita')
      expect(dita_formatter).to receive(:format).with('output/tmp/html_from_dita', 'output/tmp/formatted_dita')
      expect(dita_formatter).to receive(:format_subnav).with(dita_section,
                                                             'output/master_middleman/source/subnavs',
                                                             '<div>this is the dita subnav template</div>',
                                                             '<a href="subnav/link">Link</a>')
                                .and_return Subnav.new(['formatted_json_links'], '<div data-props-location="output/master_middleman/source/subnavs/data_props_file.json">this is the dita subnav template</div>')

      expect(fs_accessor).to receive(:write).with(text: ['formatted_json_links'],
                                                  to: props_file_location)

      expect(fs_accessor).to receive(:write).with(text: '<div data-props-location="output/master_middleman/source/subnavs/data_props_file.json">this is the dita subnav template</div>',
                                                  to: 'output/master_middleman/source/subnavs/my_dita_section_subnav.erb')

      expect(fs_accessor).to receive(:copy_named_directory_with_path).with('images',
                                                                           'output/tmp/html_from_dita',
                                                                           'output/master_middleman/source')
      expect(fs_accessor).to receive(:copy_contents).with('output/tmp/formatted_dita',
                                                          'output/master_middleman/source')

      local_dita_preprocessor.preprocess(dita_section,
                                         'output/tmp/html_from_dita',
                                         'output/tmp/formatted_dita',
                                         'output/master_middleman/source',
                                         'output/master_middleman/source/subnavs',
                                         'output/master_middleman/source/subnavs/_dita_subnav_template')

    end
  end
end