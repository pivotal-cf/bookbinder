require 'find'
require 'pathname'
require 'nokogiri'

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

    def read_html_in_tag(path: nil, marker: nil)
      doc = Nokogiri::XML(File.open path)
      doc.css(marker).inner_html
    end

    def remove_directory(path)
      FileUtils.rm_rf(path)
    end

    def make_directory(path)
      FileUtils.mkdir_p(path)
    end

    def copy(src, dest)
      FileUtils.cp_r src, dest
    end

    def copy_contents(src, dest)
      contents = Dir.glob File.join(src, '**')
      contents.each do |dir|
        FileUtils.cp_r dir, dest
      end
    end

    def copy_named_directory_with_path(dir_name, src, dest)
      contents = Dir.glob File.join(src, "**/#{dir_name}")
      contents.each do |dir|
        relative_path_to_dir = relative_path_from(src, dir)
        extended_dest = File.join dest, relative_path_to_dir
        FileUtils.mkdir_p extended_dest
        copy_contents dir, extended_dest
      end
    end

    def rename_file(path, new_name)
      new_path = File.expand_path File.join path, '..', new_name
      File.rename(path, new_path)
    end

    def find_files_with_ext(ext, path)
      Dir[File.join path, '**/*'].select { |file| File.basename(file).match(ext) }
    end

    def relative_path_from(src, target)
      target_path = Pathname(File.absolute_path target)
      relative_path = target_path.relative_path_from(Pathname(File.absolute_path src))
      relative_path.to_s
    end

  end

end
