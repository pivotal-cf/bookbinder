require_relative '../../../lib/bookbinder/local_file_system_accessor'
require_relative '../../helpers/use_fixture_repo'

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

    describe 'reading a file' do
      it 'returns the contents of the file as a string' do
        Dir.mktmpdir do |tmpdir|
          filepath = File.join tmpdir, 'filename.txt'
          File.write(filepath, 'this is some text')

          expect(local_file_system_accessor.read filepath).to eq 'this is some text'
        end
      end
    end

    describe 'reading from a particular part of a file' do
      it 'returns the desired content as a string' do
        Dir.mktmpdir do |tmpdir|
          filepath = File.join tmpdir, 'filename.txt'
          File.write(filepath, '<head><body>this is some text</body></head>')

          expect(local_file_system_accessor.read_from_marker_to(path: filepath,
                                                                marker: '<head>',
                                                                to: '</head>')).
              to eq '<body>this is some text</body>'
        end
      end

      context 'when the files are multiline' do
        use_fixture_repo('my-dita-output-repo')

        it 'returns the correct selection' do
          filepath =         File.expand_path './output.html'

          expect(local_file_system_accessor.read_from_marker_to(path: filepath,
                                                                marker: '<title>',
                                                                to: '</title>')).
              to eq 'GemFire XD Features and Benefits'
        end
      end
    end

    describe 'removing a directory' do
      it 'remove the specified directory from the filesystem' do
        fs_accessor = local_file_system_accessor

        Dir.mktmpdir do |tmpdir|
          dirpath = File.join tmpdir, 'target_dir'
          Dir.mkdir dirpath

          expect { fs_accessor.remove_directory dirpath }.
              to change{ Dir.exist? dirpath }.from(true).to(false)
        end
      end

      it 'removes all the contents of the specified directory' do
        fs_accessor = local_file_system_accessor

        Dir.mktmpdir do |tmpdir|
          dirpath = File.join tmpdir, 'target_dir'
          Dir.mkdir dirpath
          filepath = File.join dirpath, 'filename.txt'
          fs_accessor.write(to: filepath, text: 'this is some text')

          expect { fs_accessor.remove_directory dirpath }.
              to change{ File.exist? filepath }.from(true).to(false)
        end
      end

      it 'removes any nested directories' do
        fs_accessor = local_file_system_accessor

        Dir.mktmpdir do |tmpdir|
          dirpath = File.join tmpdir, 'target_dir'
          Dir.mkdir dirpath
          nested_dir_path = File.join dirpath, 'nested_dir'
          Dir.mkdir nested_dir_path

          expect { fs_accessor.remove_directory dirpath }.
              to change{ File.exist? nested_dir_path }.from(true).to(false)
        end
      end
    end

    describe 'making a directory' do
      it 'creates the directory' do
        fs_accessor = local_file_system_accessor

        Dir.mktmpdir do |tmpdir|
          dirpath = File.join tmpdir, 'target_dir'

          expect { fs_accessor.make_directory dirpath }.
              to change{ Dir.exist? dirpath }.from(false).to(true)
        end
      end

      it 'creates any intermediate directories' do
        fs_accessor = local_file_system_accessor

        Dir.mktmpdir do |tmpdir|
          intermediate_dirpath = File.join tmpdir, 'intermediate_dir'
          dirpath = File.join intermediate_dirpath, 'target_dir'

          expect { fs_accessor.make_directory dirpath }.
              to change{ Dir.exist? intermediate_dirpath }.from(false).to(true)
        end
      end
    end

    describe 'copying a directory' do
      it 'copies a directory to a specified location' do
        fs_accessor = local_file_system_accessor

        Dir.mktmpdir do |tmpdir|
          dest_dir_path = File.join(tmpdir, 'dest_dir')
          source_dir_path = File.join tmpdir, 'source_dir'
          FileUtils.mkdir_p(dest_dir_path)
          FileUtils.mkdir_p(source_dir_path)

          expect { fs_accessor.copy source_dir_path, dest_dir_path }.
              to change{ Dir.exist? File.join(dest_dir_path, 'source_dir') }.from(false).to(true)
        end
      end
    end

    describe 'copying a file' do
      it 'copies a file to a specified location' do
        fs_accessor = local_file_system_accessor

        Dir.mktmpdir do |tmpdir|
          dest_dir_path = File.join(tmpdir, 'dest_dir')
          FileUtils.mkdir_p(dest_dir_path)

          filepath = File.join tmpdir, 'file.txt'
          File.write filepath, 'this is some text'

          expect { fs_accessor.copy filepath, dest_dir_path }.
              to change{ File.exist?(File.join dest_dir_path, 'file.txt') }.from(false).to(true)
        end
      end
    end

    describe 'renaming a file' do
      it 'renames a file in the same location' do
        fs_accessor = local_file_system_accessor

        Dir.mktmpdir do |tmpdir|
          filepath = File.join tmpdir, 'file.txt'
          File.write filepath, 'this is some text'

          expect { fs_accessor.rename_file filepath, 'changed_file.txt' }.
              to change{ File.exist?(File.join tmpdir, 'changed_file.txt') }.from(false).to(true)
        end
      end
    end

    describe 'finding all files with an extension' do
      it 'finds all files containing the extension in the given directory' do
        fs_accessor = local_file_system_accessor

        Dir.mktmpdir do |tmpdir|
          filepath = File.join tmpdir, 'file.txt'
          File.write filepath, 'this is some text'

          expect(fs_accessor.find_files_with_ext('.txt', tmpdir)).to include filepath
        end
      end

      it 'finds all files containing the extension in any subdirectories' do
        fs_accessor = local_file_system_accessor

        Dir.mktmpdir do |tmpdir|
          filepath = File.join tmpdir, 'file.txt'
          File.write filepath, 'this is some text'

          nested_filepath = File.join tmpdir, 'nested-dir', 'nested-file.txt'
          FileUtils.mkdir File.join tmpdir, 'nested-dir'
          File.write nested_filepath, 'this is some text in a nested file'

          expect(fs_accessor.find_files_with_ext('.txt', tmpdir)).to include filepath, nested_filepath
        end
      end
    end
  end
end

