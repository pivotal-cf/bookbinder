require_relative '../../../lib/bookbinder/local_file_system_accessor'
require_relative '../../helpers/use_fixture_repo'

module Bookbinder
  describe LocalFileSystemAccessor do
    def fs_accessor
      LocalFileSystemAccessor.new
    end

    describe 'writing to a new file' do
      it 'appends text to the specified place in the filesystem' do
        Dir.mktmpdir do |tmpdir|
          filepath = File.join tmpdir, 'filename.txt'
          fs_accessor.write(to: filepath, text: 'this is some text')
          fs_accessor.write(to: filepath, text: ' and this is more text')
          expect(File.read(filepath)).to eq 'this is some text and this is more text'
        end
      end

      it 'creates any intermediate directories' do
        Dir.mktmpdir do |tmpdir|
          filepath = File.join tmpdir, 'intermediate_dir', 'filename.txt'

          fs_accessor.write(to: filepath, text: 'this is some text')
          expect(Dir.exist? File.join tmpdir, 'intermediate_dir').to eq true
        end
      end

      it 'returns the location of the written file' do
        Dir.mktmpdir do |tmpdir|
          filepath = File.join tmpdir, 'filename.txt'
          location_of_file = fs_accessor.write(to: filepath,
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

          expect(fs_accessor.read filepath).to eq 'this is some text'
        end
      end
    end

    describe 'removing a directory' do
      it 'removes the specified directory from the filesystem' do
        Dir.mktmpdir do |tmpdir|
          dirpath = File.join tmpdir, 'target_dir'
          Dir.mkdir dirpath

          expect { fs_accessor.remove_directory dirpath }.
              to change{ Dir.exist? dirpath }.from(true).to(false)
        end
      end

      it 'removes all the contents of the specified directory' do
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

    describe 'emptying a directory' do
      it 'removes contents of the dir, but not the dir itself' do
        Dir.mktmpdir do |tmpdir|
          base = Pathname(tmpdir).join(*%w(a b))
          base.join('c').mkpath
          base.join('d').mkpath

          fs_accessor.empty_directory(base)
          expect(base.join('c')).not_to exist
          expect(base.join('d')).not_to exist
          expect(base).to exist
        end
      end
    end

    describe 'making a directory' do
      it 'creates the directory' do
        Dir.mktmpdir do |tmpdir|
          dirpath = File.join tmpdir, 'target_dir'

          expect { fs_accessor.make_directory dirpath }.
              to change{ Dir.exist? dirpath }.from(false).to(true)
        end
      end

      it 'creates any intermediate directories' do
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

    describe 'copying files preserving intermediate directories' do
      it 'creates the relative intermediate directories in the destination' do
        Dir.mktmpdir do |tmpdir|
          dest_dir_path = File.join(tmpdir, 'dest_dir')
          intermdiate_path = File.join tmpdir, 'intermediate'
          src_file_path = File.join intermdiate_path, 'file.txt'
          FileUtils.mkdir_p(intermdiate_path)
          FileUtils.touch(src_file_path)

          expect { fs_accessor.copy_including_intermediate_dirs src_file_path, tmpdir, dest_dir_path }.
              to change{ File.exist? File.join(dest_dir_path, 'intermediate', 'file.txt') }.from(false).to(true)
        end
      end
    end

    describe 'copying a file' do
      it 'copies a file to a specified location' do
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
        Dir.mktmpdir do |tmpdir|
          dest_dir_path = File.join(tmpdir, 'dest_dir')
          source_dir_path = File.join tmpdir, 'source_dir'

          FileUtils.mkdir_p(dest_dir_path)
          nested_source_dir = File.join(source_dir_path, "some", "nested", "dir")
          FileUtils.mkdir_p(nested_source_dir)

          filepath = File.join nested_source_dir, 'file.txt'
          File.write filepath, 'this is some text'

          expect { fs_accessor.copy_contents source_dir_path, dest_dir_path }.
            to change{ File.exist? File.join(dest_dir_path, "some", "nested", "dir", "file.txt") }.
            from(false).to(true)
        end
      end

      context 'when the source directory does not exist' do
        it 'is a mistake to call copy contents' do
          Dir.mktmpdir do |tmpdir|
            dest_dir_path = File.join(tmpdir, 'dest_dir')
            source_dir_path = ""

            expect { fs_accessor.copy_contents source_dir_path, dest_dir_path }.to raise_error(Errors::ProgrammerMistake)
          end
        end
      end

      context 'when the destination directory does not exist' do
        it 'creates the directory and copies the contents to a specified location' do
          Dir.mktmpdir do |tmpdir|
            dest_dir_path = File.join(tmpdir, 'dest_dir')
            source_dir_path = File.join tmpdir, 'source_dir'

            FileUtils.mkdir_p(source_dir_path)

            filepath = File.join source_dir_path, 'file.txt'
            File.write filepath, 'this is some text'

            expect { fs_accessor.copy_contents source_dir_path, dest_dir_path }.
                to change{ File.exist? File.join(dest_dir_path, 'file.txt') }.from(false).to(true)
          end
        end
      end

      context 'when there are intermediate directories' do
        it 'copies each file only once and preserves the intermediate directories in the copied filepaths' do
          Dir.mktmpdir do |tmpdir|
            dest_dir_path = File.join(tmpdir, 'dest_dir')
            intermdiate_path = File.join tmpdir, 'intermediate'
            FileUtils.mkdir_p(intermdiate_path)
            inner_dir = File.join intermdiate_path, 'inner_dir'
            FileUtils.mkdir_p(inner_dir)
            src_file_path = File.join inner_dir, 'file.txt'
            FileUtils.touch(src_file_path)

            expect { fs_accessor.copy_contents intermdiate_path, dest_dir_path }.
                to change{ File.exist? File.join(tmpdir, 'dest_dir', 'inner_dir', 'file.txt') }.
                       from(false).to(true)

            expect(File.exist? File.join(dest_dir_path, 'file.txt')).to_not be_truthy
          end
        end
      end
    end

    describe 'linking a directory' do
      it 'links and creates intermediate dirs' do
        Dir.mktmpdir do |tmpdir|
          src = Pathname(tmpdir).join('foo').tap(&:mkpath)
          dst = Pathname(tmpdir).join('bar/baz')
          fs_accessor.link_creating_intermediate_dirs(src.to_s, dst.to_s)
          expect(dst).to exist
          expect(dst).to be_symlink
        end
      end
    end

    describe 'renaming a file' do
      it 'renames a file in the same location' do
        Dir.mktmpdir do |tmpdir|
          filepath = File.join tmpdir, 'file.txt'
          File.write filepath, 'this is some text'

          expect { fs_accessor.rename_file filepath, 'changed_file.txt' }.
              to change{ File.exist?(File.join tmpdir, 'changed_file.txt') }.from(false).to(true)
        end
      end
    end

    describe 'finding all files with extensions' do
      it 'finds all files containing the extensions in the given directory' do
        Dir.mktmpdir do |tmpdir|
          filepath = File.join tmpdir, 'file.txt'
          File.write filepath, 'this is some text'

          expect(fs_accessor.find_files_with_ext('txt', tmpdir)).to eq [filepath]
        end
      end

      it 'finds all files containing the extensions in any subdirectories' do
        Dir.mktmpdir do |tmpdir|
          filepath = File.join tmpdir, 'file.txt'
          File.write filepath, 'this is some text'

          nested_filepath = File.join tmpdir, 'nested-dir', 'nested-file.txt'
          FileUtils.mkdir File.join tmpdir, 'nested-dir'
          File.write nested_filepath, 'this is some text in a nested file'

          expect(fs_accessor.find_files_with_ext('txt', tmpdir)).to include filepath, nested_filepath
        end
      end
    end

    describe 'calculating a relative path' do
      it 'returns the path from the source to the target directory' do
        Dir.mktmpdir do |tmpdir|
          nested_filepath = File.join tmpdir, 'nested-dir', 'nested-file.txt'
          FileUtils.mkdir File.join tmpdir, 'nested-dir'
          File.write nested_filepath, 'this is some text in a nested file'

          expect(fs_accessor.relative_path_from(tmpdir, nested_filepath)).to eq 'nested-dir/nested-file.txt'
        end
      end
    end

    describe 'finding files in a directory' do
      it 'returns files after following symlinks' do
        Dir.mktmpdir do |dir|
          path = Pathname(dir)
          path.join("top-dir/nested/dir").mkpath
          path.join("parallel-dir/other/nested/dir").mkpath
          FileUtils.touch(path.join("top-dir/nested/dir/foo"))
          FileUtils.touch(path.join("parallel-dir/other/nested/dir/bar"))
          File.symlink(path.join("parallel-dir/other"), path.join("top-dir/other"))
          expect(fs_accessor.find_files_recursively(path.join("top-dir")).map {|p| p.to_s.sub(dir, '')}).
            to eq(%w(/top-dir/nested/dir/foo /top-dir/other/nested/dir/bar))
        end
      end
    end
  end
end

