module Bookbinder

  class DitaHtmlToMiddlemanFormatter
    def initialize(file_system_accessor)
      @file_system_accessor = file_system_accessor
    end

    def format(src, dest)
      all_files_with_ext = file_system_accessor.find_files_with_ext('.html', src)

      all_files_with_ext.map do |filepath|
        file_title_text = file_system_accessor.read_html_in_tag(path: filepath,
                                                                marker: 'title')

        file_body_text = file_system_accessor.read_html_in_tag(path: filepath,
                                                               marker: 'body')

        relative_path_to_file = file_system_accessor.relative_path_from(src, filepath)
        new_filepath = File.join dest, "#{relative_path_to_file}.erb"

        output_text = frontmatter(file_title_text) + file_body_text

        file_system_accessor.write(to: new_filepath, text: output_text)
      end
    end

    private

    attr_reader :file_system_accessor

    def frontmatter(title)
      sanitized_title = title.gsub('"', '\"')
      "---\ntitle: \"#{sanitized_title}\"\ndita: true\n---\n"
    end

  end
end
