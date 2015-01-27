require 'find'

module Bookbinder

  class LocalFileSystemAccessor
    def file_exist?(path)
      File.exist?(path)
    end

    def write(to: nil, text: nil)
      File.open(to, 'w') do |f|
        f.write(text)
      end

      to
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
  end

end
