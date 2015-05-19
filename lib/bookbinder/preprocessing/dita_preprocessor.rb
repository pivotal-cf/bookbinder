require_relative '../values/subnav'

module Bookbinder
  module Preprocessing
    class DitaPreprocessor

      ACCEPTED_IMAGE_FORMATS = %w(png jpeg jpg svg gif bmp tif tiff eps)

      def initialize(dita_formatter, local_fs_accessor, command_creator, sheller)
        @dita_formatter = dita_formatter
        @local_fs_accessor = local_fs_accessor
        @command_creator = command_creator
        @sheller = sheller
      end

      def applicable_to?(section)
        section.subnav_template == 'dita_subnav'
      end

      def preprocess(dita_sections, output_locations, options: nil, output_streams: nil)
        dita_sections.select { |dita_section| dita_section.path_to_preprocessor_attribute('ditamap_location') }.each do |dita_section|
          command = command_creator.convert_to_html_command(
            dita_section,
            dita_flags: dita_flags(options),
            write_to: output_locations.html_from_preprocessing_dir.join(dita_section.desired_directory)
          )
          status = sheller.run_command(command, output_streams.to_h)
          unless status.success?
            raise DitaToHtmlLibraryFailure.new 'The DITA-to-HTML conversion failed. ' +
              'Please check that you have specified the path to your DITA-OT library in the ENV, ' +
              'that your DITA-specific keys/values in config.yml are set, ' +
              'and that your DITA toolkit is correctly configured.'
          end

          generate_subnav(dita_section.desired_directory,
                          output_locations,
                          output_locations.source_for_site_generator.join('subnavs', '_dita_subnav_template.erb'),
                          output_locations.subnavs_for_layout_dir)
        end

        dita_sections.each do |dita_section|
          html_dir = output_locations.html_from_preprocessing_dir.join(dita_section.desired_directory)
          formatted_dir = output_locations.formatted_dir.join(dita_section.desired_directory)
          source_for_site_gen_dir = output_locations.source_for_site_generator.join(dita_section.desired_directory)

          dita_formatter.format_html html_dir, formatted_dir

          copy_images(dita_section.path_to_repository, formatted_dir)

          local_fs_accessor.copy_contents(formatted_dir, source_for_site_gen_dir)
        end
      end

      private

      attr_reader :dita_formatter, :local_fs_accessor, :command_creator, :sheller

      def generate_subnav(dita_section_dir, output_locations, dita_subnav_template_path, subnavs_dir)
        dita_subnav_template_text = local_fs_accessor.read(dita_subnav_template_path)

        tocjs_text = local_fs_accessor.read(
          File.join(
            output_locations.html_from_preprocessing_dir.join(dita_section_dir),
            'index.html')
        )
        json_props_location = File.join('dita-subnav-props.json')
        props_file_location = File.join(subnavs_dir, json_props_location)

        subnav = dita_formatter.format_subnav(dita_section_dir,
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

      def dita_flags(opts)
        matching_flags = opts.map {|o| o[flag_value_regex("dita-flags"), 1] }
        matching_flags.compact.first
      end

      def flag_value_regex(flag_name)
        Regexp.new(/--#{flag_name}=(.+)/)
      end
    end
  end
end
