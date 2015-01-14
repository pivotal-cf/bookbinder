require_relative '../../../lib/bookbinder/local_file_system_accessor'

module Bookbinder

  describe LocalFileSystemAccessor do
    let(:local_file_system_accessor) { LocalFileSystemAccessor.new }

    it 'can find if a given extension exists in a directory' do
      expect(local_file_system_accessor.contains_extension?('rb', '.')).to be_truthy
    end

    it 'can recusively find if a given extension exists in a directory' do
      expect(local_file_system_accessor.contains_extension?('ditamap', './spec/fixtures')).to be_truthy
    end

    it 'returns false if the given extension is not found in any subdirectory' do
      expect(local_file_system_accessor.contains_extension?('dummy_ext', './spec/fixtures')).to eq false
    end
  end

end
