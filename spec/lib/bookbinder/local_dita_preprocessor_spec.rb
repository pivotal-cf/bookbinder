require_relative '../../../lib/bookbinder/local_dita_preprocessor'

module Bookbinder
  describe LocalDitaPreprocessor do
    it 'converts, formats, provides a subnav, and copies the resulting DITA sections into the output directory' do
      dita_converter = double('dita_converter')
      dita_formatter = double('dita_formatter')
      local_file_system_accessor = double('fs_accessor', read: 'this is the dita subnav template')
      local_dita_preprocessor = LocalDitaPreprocessor.new(dita_converter, dita_formatter, local_file_system_accessor)

      dita_section = double('dita_section')

      expect(dita_converter).to receive(:convert).with(dita_section, to: 'output/tmp/html_from_dita')
      expect(dita_formatter).to receive(:format).with('output/tmp/html_from_dita', 'output/tmp/formatted_dita')
      expect(dita_formatter).to receive(:format_subnavs).with(dita_section,
                                                              'output/tmp/html_from_dita',
                                                              'output/master_middleman/source/subnavs',
                                                              'this is the dita subnav template')
      expect(local_file_system_accessor).to receive(:copy_named_directory_with_path).with('images',
                                                                                          'output/tmp/html_from_dita',
                                                                                          'output/master_middleman/source')
      expect(local_file_system_accessor).to receive(:copy_contents).with('output/tmp/formatted_dita',
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