require 'find'

module Bookbinder

  class LocalFileSystemAccessor
    def file_exist?(path)
      File.exist?(path)
    end

    def write(to: , text: )
      File.open(to, 'w') do |f|
        f.write(text)
      end

      to
    end
  end

end
