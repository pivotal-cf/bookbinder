require 'find'
require 'pathname'
require_relative 'errors/programmer_mistake'

module Bookbinder

  class LocalFilesystemAccessor
    def file_exist?(path)
      File.exist?(path)
    end

    def is_file?(path)
      File.file?(path)
    end

    def is_dir?(path)
      Dir.exists?(path)
    end

    def write(to: nil, text: nil)
      make_directory(File.dirname to)

      File.open(to, 'a') do |f|
        f.write(text)
      end

      to
    end

    def overwrite(to: nil, text: nil)
      File.delete(to) if file_exist?(to)
      write(to: to, text: text)
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

    def copy_and_rename(src, dest)
      make_directory(Pathname(dest).dirname)
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
      all_files = find_files_recursively(path)
      matching_files = all_files.select {|p| p.to_s.match(/\.#{ext}/) }
      matching_files.map(&:to_s)
    end

    def relative_path_from(src, target)
      target_path = Pathname(File.absolute_path target)
      relative_path = target_path.relative_path_from(Pathname(File.absolute_path src))
      relative_path.to_s
    end

    def find_files_recursively(from)
      `find -L #{from} -type f`.
        lines.
        map(&:chomp).
        map(&Pathname.method(:new)).
        reject {|p| p.to_s.match %r{/\.}}.
        reject(&:directory?)
    end

    def find_files_extension_agnostically(pattern, directory='.')
      extensionless_pattern = File.join(File.dirname(pattern), File.basename(pattern).split('.').first)

      `find -L #{directory} -path '*/#{extensionless_pattern}.*' -type f`.
        lines.
        map(&:chomp).
        map(&Pathname.method(:new))
    end

    def source_file_exists?(directory, path_to_file)
      path = Pathname(path_to_file.split('/').last)
      source_file_found = false

      Pathname(directory).ascend do |dir|
        source_file_found = true if dir.entries.any? { |entry| entry == path }
      end
      source_file_found
    end
  end
end
