require_relative '../../../lib/bookbinder/local_file_system_accessor'

module Bookbinder
  describe LocalFileSystemAccessor do
    def local_file_system_accessor
      LocalFileSystemAccessor.new
    end

    describe 'writing to a new file' do
      it 'writes text to the specified place in the filesystem' do
        Dir.mktmpdir do |tmpdir|
          filepath = File.join tmpdir, 'filename.txt'
          local_file_system_accessor.write(to: filepath, text: 'this is some text')
          expect(File.read(filepath)).to eq 'this is some text'
        end
      end

      it 'returns the location of the written file' do
        Dir.mktmpdir do |tmpdir|
          filepath = File.join tmpdir, 'filename.txt'
          location_of_file = local_file_system_accessor.write(to: filepath,
                                                              text: 'this is some text')
          expect(location_of_file).to eq filepath
        end
      end
    end
  end
end
