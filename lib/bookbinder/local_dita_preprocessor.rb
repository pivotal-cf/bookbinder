require_relative 'values/subnav'

module Bookbinder
  class LocalDitaPreprocessor

    def initialize(dita_converter, dita_formatter, local_file_system_accessor)
      @dita_converter = dita_converter
      @dita_formatter = dita_formatter
      @local_file_system_accessor = local_file_system_accessor
    end

    def preprocess(dita_section,
                   subnavs_dir,
                   dita_subnav_template_path)
      dita_converter.convert_to_html dita_section, write_to: dita_section.html_from_dita_section_dir

      dita_formatter.format_html dita_section.html_from_dita_section_dir, dita_section.formatted_section_dir

      dita_subnav_template_text = local_file_system_accessor.read(dita_subnav_template_path)
      tocjs_text = local_file_system_accessor.read(File.join dita_section.html_from_dita_section_dir, 'index.html')

      json_props_location = File.join(dita_section.directory + '-props.json')
      props_file_location = File.join(subnavs_dir, json_props_location)

      subnav = dita_formatter.format_subnav(dita_section,
                                            dita_subnav_template_text,
                                            json_props_location,
                                            tocjs_text)

      local_file_system_accessor.write text: subnav.json_links, to: props_file_location

      local_file_system_accessor.write text: subnav.text,
                                       to: File.join(subnavs_dir,
                                                     filename="#{dita_section.directory}_subnav.erb")

      local_file_system_accessor.copy_named_directory_with_path('images',
                                                                dita_section.html_from_dita_section_dir,
                                                                dita_section.section_source_for_site_generator)

      local_file_system_accessor.copy_contents(dita_section.formatted_section_dir,
                                               dita_section.section_source_for_site_generator)
    end


    private

    attr_reader :dita_converter, :dita_formatter, :local_file_system_accessor

  end
end
