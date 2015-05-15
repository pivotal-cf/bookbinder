require_relative 'values/subnav'

module Bookbinder
  class DitaPreprocessor

    ACCEPTED_IMAGE_FORMATS = %w(png jpeg jpg svg gif bmp tif tiff eps)

    def initialize(dita_formatter, local_fs_accessor)
      @dita_formatter = dita_formatter
      @local_fs_accessor = local_fs_accessor
    end

    def preprocess(dita_sections,
                   output_locations,
                   subnavs_dir,
                   dita_subnav_template_path,
                   &block)
      ditamap_location_sections = dita_sections.select { |dita_section| dita_section.path_to_preprocessor_attribute('ditamap_location') }
      ditamap_location_sections.each do |dita_section|
        block.call(dita_section)
        generate_subnav(dita_section, output_locations, dita_subnav_template_path, subnavs_dir)
      end

      dita_sections.each do |dita_section|
        html_dir = output_locations.html_from_dita_dir.join(dita_section.directory)
        formatted_dir = output_locations.formatted_dir.join(dita_section.directory)
        source_for_site_gen_dir = output_locations.source_for_site_generator.join(dita_section.directory)

        dita_formatter.format_html html_dir, formatted_dir

        copy_images(dita_section.path_to_repository, formatted_dir)

        local_fs_accessor.copy_contents(formatted_dir, source_for_site_gen_dir)
      end
    end

    private

    attr_reader :dita_formatter, :local_fs_accessor

    def generate_subnav(dita_section, output_locations, dita_subnav_template_path, subnavs_dir)
      dita_subnav_template_text = local_fs_accessor.read(dita_subnav_template_path)

      tocjs_text = local_fs_accessor.read(
        File.join(
          output_locations.html_from_dita_dir.join(dita_section.directory),
          'index.html')
      )
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
