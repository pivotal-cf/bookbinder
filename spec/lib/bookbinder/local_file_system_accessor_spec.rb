require_relative '../../../lib/bookbinder/local_file_system_accessor'
require_relative '../../helpers/use_fixture_repo'

module Bookbinder
  describe LocalFileSystemAccessor do
    def local_file_system_accessor
      LocalFileSystemAccessor.new
    end

    describe 'writing to a new file' do
      it 'appends text to the specified place in the filesystem' do
        Dir.mktmpdir do |tmpdir|
          filepath = File.join tmpdir, 'filename.txt'
          local_file_system_accessor.write(to: filepath, text: 'this is some text')
          local_file_system_accessor.write(to: filepath, text: ' and this is more text')
          expect(File.read(filepath)).to eq 'this is some text and this is more text'
        end
      end

      it 'creates any intermediate directories' do
        Dir.mktmpdir do |tmpdir|
          filepath = File.join tmpdir, 'intermediate_dir', 'filename.txt'

          local_file_system_accessor.write(to: filepath, text: 'this is some text')
          expect(Dir.exist? File.join tmpdir, 'intermediate_dir').to eq true
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

    describe 'copying directories with a specific name' do
      it 'copies the contents of all directories matching the specified name to the destination' do
        fs_accessor = local_file_system_accessor

        Dir.mktmpdir do |tmpdir|
          intermediate_dirpath = File.join tmpdir, 'intermediate_dir'
          dirpath = File.join intermediate_dirpath, 'target_dir'
          filepath = File.join dirpath, 'file.txt'
          FileUtils.mkdir_p dirpath
          FileUtils.touch filepath
          dest_path = File.join tmpdir, 'destination'
          FileUtils.mkdir_p dest_path

          expected_filepath_in_destination = File.join dest_path, 'intermediate_dir/target_dir/file.txt'
          expect { fs_accessor.copy_named_directory_with_path 'target_dir', tmpdir, dest_path }.
              to change{ File.exist? expected_filepath_in_destination }.from(false).to(true)
        end
      end

      context 'when the directory found has nested directories in its path' do
        it 'recreates the nested directories inside the destination directory' do
          fs_accessor = local_file_system_accessor

          Dir.mktmpdir do |tmpdir|
            intermediate_dirpath = File.join tmpdir, 'intermediate_dir'
            dirpath = File.join intermediate_dirpath, 'target_dir'
            dest_path = File.join tmpdir, 'destination'
            FileUtils.mkdir_p dirpath
            FileUtils.mkdir_p dest_path

            expected_intermediate_path_in_destination = File.join dest_path, 'intermediate_dir'

            expect { fs_accessor.copy_named_directory_with_path 'target_dir', tmpdir, dest_path }.
                to change{ Dir.exist? expected_intermediate_path_in_destination }.from(false).to(true)
          end
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
              to change { File.exist?(File.join dest_dir_path, 'file.txt') }.from(false).to(true)
        end
      end

      context 'when the destination dir does not exist' do
        it 'creates the destination dir and copies the contents' do
          fs_accessor = local_file_system_accessor

          Dir.mktmpdir do |tmpdir|
            dest_dir_path = File.join(tmpdir, 'dest_dir')

            filepath = File.join tmpdir, 'file.txt'
            File.write filepath, 'this is some text'

            expect { fs_accessor.copy filepath, dest_dir_path }.
                to change { File.exist?(File.join dest_dir_path, 'file.txt') }.from(false).to(true)
          end
        end
      end
    end

    describe 'copying the contents of a directory' do
      it 'recursively copies the contents to a specified location' do
        fs_accessor = local_file_system_accessor

        Dir.mktmpdir do |tmpdir|
          dest_dir_path = File.join(tmpdir, 'dest_dir')
          source_dir_path = File.join tmpdir, 'source_dir'

          FileUtils.mkdir_p(dest_dir_path)
          FileUtils.mkdir_p(source_dir_path)

          filepath = File.join source_dir_path, 'file.txt'
          File.write filepath, 'this is some text'

          expect { fs_accessor.copy_contents source_dir_path, dest_dir_path }.
              to change{ File.exist? File.join(dest_dir_path, 'file.txt') }.from(false).to(true)
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

    describe 'calculating a relative path' do
      it 'returns the path from the source to the target directory' do
        fs_accessor = local_file_system_accessor

        Dir.mktmpdir do |tmpdir|
          nested_filepath = File.join tmpdir, 'nested-dir', 'nested-file.txt'
          FileUtils.mkdir File.join tmpdir, 'nested-dir'
          File.write nested_filepath, 'this is some text in a nested file'

          expect(fs_accessor.relative_path_from(tmpdir, nested_filepath)).to eq 'nested-dir/nested-file.txt'
        end
      end
    end
  end
end

