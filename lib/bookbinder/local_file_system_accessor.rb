require 'find'

module Bookbinder

  class LocalFileSystemAccessor
    def file_exist?(path)
      File.exist?(path)
    end

    def contains_extension?(file_extension, path)
      Find.find(path) do |path|
        return true if path =~ /.*\.#{file_extension}$/
      end

      false
    end
  end

end
