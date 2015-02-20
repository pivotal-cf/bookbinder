module Bookbinder

  class DitaHtmlToMiddlemanFormatter
    def initialize(file_system_accessor, subnav_formatter, html_document_manipulator)
      @file_system_accessor = file_system_accessor
      @subnav_formatter = subnav_formatter
      @html_document_manipulator = html_document_manipulator
    end

    def format(src, dest)
      all_files_with_ext = file_system_accessor.find_files_with_ext('.html', src)

      all_files_with_ext.map do |filepath|
        file_text = file_system_accessor.read filepath
        file_title_text = html_document_manipulator.read_html_in_tag(document: file_text,
                                                                     tag: 'title')

        file_body_text = html_document_manipulator.read_html_in_tag(document: file_text,
                                                                    tag: 'body')

        relative_path_to_file = file_system_accessor.relative_path_from(src, filepath)
        new_filepath = File.join dest, "#{relative_path_to_file}.erb"

        output_text = frontmatter(file_title_text) + file_body_text

        file_system_accessor.write(to: new_filepath, text: output_text)
      end
    end

    def format_subnavs(dita_sections,
                       html_from_dita_dir,
                       subnav_destination_dir,
                       subnav_template_text)
      dita_sections.each do |dita_section|
        tocjs_text = file_system_accessor.read(File.join html_from_dita_dir, dita_section.directory, 'index.html')

        formatted_tocjs = subnav_formatter.format(tocjs_text, dita_section.directory)

        nav_text = html_document_manipulator.insert_text_after_selector(document: subnav_template_text,
                                                                        text: formatted_tocjs,
                                                                        selector:'div.nav-content')

        file_system_accessor.write text: nav_text, to: File.join(subnav_destination_dir, filename="#{dita_section.directory}_subnav.erb")
      end
    end

    private

    attr_reader :file_system_accessor, :subnav_formatter, :html_document_manipulator

    def frontmatter(title)
      sanitized_title = title.gsub('"', '\"')
      "---\ntitle: \"#{sanitized_title}\"\ndita: true\n---\n"
    end
  end

end
