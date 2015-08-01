require 'find'
require 'pathname'
require 'nokogiri'
require_relative 'errors/programmer_mistake'

module Bookbinder

  class LocalFileSystemAccessor
    def file_exist?(path)
      File.exist?(path)
    end

    def write(to: nil, text: nil)
      make_directory(File.dirname to)

      File.open(to, 'a') do |f|
        f.write(text)
      end

      to
    end

    def read(path)
      File.read(path)
    end

    def empty_directory(path)
      FileUtils.rm_rf(File.join(path, '.'))
    end

    def remove_directory(path)
      FileUtils.rm_rf(path)
    end

    def make_directory(path)
      FileUtils.mkdir_p(path)
    end

    def copy(src, dest)
      make_directory(dest)
      FileUtils.cp_r src, dest
    end

    def copy_contents(src, dest)
      raise Errors::ProgrammerMistake.new("The method copy_contents cannot copy the contents of the directory '#{src}' because it was not found.") unless Dir.exists?(src)
      copy "#{src}/.", dest
    end

    def copy_including_intermediate_dirs(file, root, dest)
      path_within_destination = relative_path_from(root, file)
      extended_dest = File.dirname(File.join dest, path_within_destination)
      copy file, extended_dest
    end

    def link_creating_intermediate_dirs(src, dst)
      FileUtils.mkdir_p(File.dirname(dst))
      File.symlink(src, dst)
    end

    def rename_file(path, new_name)
      new_path = File.expand_path File.join path, '..', new_name
      File.rename(path, new_path)
    end

    def find_files_with_ext(ext, path)
      Dir[File.join path, "**/*.#{ext}"]
    end

    def relative_path_from(src, target)
      target_path = Pathname(File.absolute_path target)
      relative_path = target_path.relative_path_from(Pathname(File.absolute_path src))
      relative_path.to_s
    end

    def find_lines_recursively(from, pattern)
      Find.find(from) do |dir|
        path = Pathname(dir)
        if path.directory? && path.basename.to_s[0] == ?.
          Find.prune
        elsif path.directory?
          next
        else
          scanned, * = path.read.scan(pattern)
          if scanned
            return scanned
          else
            Find.prune
          end
        end
      end
      ""
    end
  end
end
