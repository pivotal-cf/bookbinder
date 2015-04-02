require_relative 'values/subnav'

module Bookbinder
  class DitaPreprocessor

    ACCEPTED_IMAGE_FORMATS = %w(png jpeg jpg svg gif bmp tif tiff eps)

    def initialize(command_creator, dita_formatter, local_fs_accessor)
      @command_creator = command_creator
      @dita_formatter = dita_formatter
      @local_fs_accessor = local_fs_accessor
    end

    def preprocess(dita_sections,
                   subnavs_dir,
                   dita_subnav_template_path,
                   &block)
      ditamap_location_sections = dita_sections.select { |dita_section| dita_section.ditamap_location }
      ditamap_location_sections.each do |dita_section|
        block.call(dita_section)
        generate_subnav(dita_section, dita_subnav_template_path, subnavs_dir)
      end

      dita_sections.each do |dita_section|
        dita_formatter.format_html dita_section.html_from_dita_section_dir, dita_section.formatted_section_dir

        copy_images(dita_section.path_to_local_repo, dita_section.formatted_section_dir)

        local_fs_accessor.copy_contents(dita_section.formatted_section_dir,
                                        dita_section.section_source_for_site_generator)
      end
    end

    private

    attr_reader :command_creator, :dita_formatter, :local_fs_accessor

    def generate_subnav(dita_section, dita_subnav_template_path, subnavs_dir)
      dita_subnav_template_text = local_fs_accessor.read(dita_subnav_template_path)

      tocjs_text = local_fs_accessor.read(File.join dita_section.html_from_dita_section_dir, 'index.html')
      json_props_location = File.join('dita-subnav-props.json')
      props_file_location = File.join(subnavs_dir, json_props_location)

      subnav = dita_formatter.format_subnav(dita_section,
                                            dita_subnav_template_text,
                                            json_props_location,
                                            tocjs_text)

     local_fs_accessor.write text: subnav.json_links, to: props_file_location

     local_fs_accessor.write text: subnav.text,
                                       to: File.join(subnavs_dir, "dita_subnav.erb")
    end

    def copy_images(src, dest)
      image_paths = ACCEPTED_IMAGE_FORMATS.map do |format|
        local_fs_accessor.find_files_with_ext(format, src)
      end.flatten

      image_paths.each do |image_path|
        local_fs_accessor.copy_including_intermediate_dirs(image_path,
                                                           src,
                                                           dest)
      end
    end

  end
end
