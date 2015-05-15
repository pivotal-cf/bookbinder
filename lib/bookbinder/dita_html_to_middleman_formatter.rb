require_relative 'values/subnav'

module Bookbinder

  class DitaHtmlToMiddlemanFormatter
    def initialize(file_system_accessor, subnav_formatter, html_document_manipulator)
      @file_system_accessor = file_system_accessor
      @subnav_formatter = subnav_formatter
      @html_document_manipulator = html_document_manipulator
    end

    def format_html(src, dest)
      all_files_with_ext = file_system_accessor.find_files_with_ext('html', src)

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

    def format_subnav(path_to_dita_section,
                      subnav_template_text,
                      json_props_location,
                      unformatted_subnav_text)
      formatted_json_links = subnav_formatter.get_links_as_json(unformatted_subnav_text,
                                                                path_to_dita_section)

      nav_text = html_document_manipulator.set_attribute(document: subnav_template_text,
                                                         selector: 'div.nav-content',
                                                         attribute: 'data-props-location',
                                                         value: json_props_location)
      Subnav.new(formatted_json_links, nav_text)
    end

    private

    attr_reader :file_system_accessor, :subnav_formatter, :html_document_manipulator

    def frontmatter(title)
      sanitized_title = title.gsub('"', '\"')
      "---\ntitle: \"#{sanitized_title}\"\ndita: true\n---\n"
    end
  end

end
