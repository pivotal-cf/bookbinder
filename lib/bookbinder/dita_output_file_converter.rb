module Bookbinder

  class DitaOutputFileConverter
    def initialize(file_accessor)
      @file_accessor = file_accessor
    end

    def convert(dir)
      all_files_with_ext = file_accessor.find_files_with_ext('.html', dir)

      all_files_with_ext.map do |filepath|
        new_filename = File.basename(filepath) + '.erb'
        file_accessor.rename_file filepath, new_filename
      end
    end

    private

    attr_reader :file_accessor

  end
end
