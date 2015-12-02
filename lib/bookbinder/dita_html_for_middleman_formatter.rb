module Bookbinder

  class DitaHtmlForMiddlemanFormatter
    def initialize(file_system_accessor, html_document_manipulator)
      @file_system_accessor = file_system_accessor
      @html_document_manipulator = html_document_manipulator
    end

    def format_html(src, dest)
      all_files_with_ext = file_system_accessor.find_files_with_ext('html', src)

      all_files_with_ext.map do |filepath|
        file_text = file_system_accessor.read(filepath)

        file_title_text = html_document_manipulator.read_html_in_tag(document: file_text,
                                                                     tag: 'title')

        file_body_text = html_document_manipulator.read_html_in_tag(document: file_text,
                                                                    tag: 'body')

        cleansed_body_text = revert_to_erb(file_body_text)

        relative_path_to_file = file_system_accessor.relative_path_from(src, filepath)
        new_filepath = File.join dest, "#{relative_path_to_file}.erb"

        output_text = frontmatter(file_title_text) + cleansed_body_text

        file_system_accessor.write(to: new_filepath, text: output_text)
      end
    end

    private

    attr_reader :file_system_accessor, :html_document_manipulator

    def frontmatter(title)
      sanitized_title = title.gsub('"', '\"')
      "---\ntitle: \"#{sanitized_title}\"\ndita: true\n---\n"
    end

    def revert_to_erb(text)
      text.gsub('&lt;%', '<%').gsub('%&gt;', '%>').gsub('&lt;\%', '&lt;%')
    end
  end
end
