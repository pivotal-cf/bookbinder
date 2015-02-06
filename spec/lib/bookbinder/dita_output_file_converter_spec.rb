require_relative '../../../lib/bookbinder/dita_output_file_converter'
require_relative '../../../lib/bookbinder/local_file_system_accessor'
require_relative '../../helpers/use_fixture_repo'

module Bookbinder
  describe DitaOutputFileConverter do

    use_fixture_repo('my-dita-output-repo')

    it 'converts all HTML files in the directory to ERB' do
      file_accessor = LocalFileSystemAccessor.new
      dita_output_converter = DitaOutputFileConverter.new(file_accessor)

      expected_filepath = File.expand_path './output.html.erb'

      dita_output_converter.convert(File.expand_path '.')
      expect(File.exist? expected_filepath).to eq true
    end

    # it 'converts all HTML files in subdirectories to ERB' do
      # file_accessor = LocalFileSystemAccessor.new
      # dita_output_converter = DitaOutputFileConverter.new(file_accessor)
      #
      # expected_filepath = File.expand_path './nested-dir/output.html.erb'
      #
      # expect(File.exist? expected_filepath).to eq true
      # dita_output_converter.convert('.')
    # end




    # it 'takes the -body- text of a DITA-outputted HTML file' do
    #   file_accessor = LocalFileSystemAccessor.new
    #   dita_output_converter = DitaOutputFileConverter.new(file_accessor)
    #
    #   expect(file_accessor).to receive(:rename_file).with('./output.html')
    #   dita_output_converter.convert('.')
    # end

    # it 'creates a new ERB file' do
    #   file_accessor = LocalFileSystemAccessor.new
    #   dita_output_converter = DitaOutputFileConverter.new(file_accessor)
    #
    #   p Dir.pwd
    #   p File.expand_path './output.html.erb'
    #
    #   expect(File.exist? './output.html.erb').to eq true
    #   dita_output_converter.convert('.')
    # end
    #
    # it 'removes the old HTML file' do
    #
    # end

  end
end