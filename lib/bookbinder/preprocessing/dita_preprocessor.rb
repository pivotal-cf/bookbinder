require_relative '../values/subnav_template'

module Bookbinder
  module Preprocessing
    class DitaPreprocessor
      DitaToHtmlLibraryFailure = Class.new(RuntimeError)

      ACCEPTED_IMAGE_FORMATS = %w(png jpeg jpg svg gif bmp tif tiff eps)

      def initialize(dita_formatter, local_fs_accessor, command_creator, sheller)
        @dita_formatter = dita_formatter
        @local_fs_accessor = local_fs_accessor
        @command_creator = command_creator
        @sheller = sheller
      end

      def applicable_to?(section)
        section.subnav_template.include?('dita_subnav') if section.subnav_template
      end

      def preprocess(dita_sections, output_locations, options: [], output_streams: nil, **_)
        dita_options = dita_flags(options)
        dita_sections.each do |dita_section|
          if dita_section.path_to_preprocessor_attribute('ditamap_location')
            convert_dita_files(dita_section,
                               command_creator,
                               dita_options,
                               output_locations.html_from_preprocessing_dir.join(dita_section.destination_directory),
                               sheller,
                               output_streams)

            generate_subnav(dita_section,
                            output_locations,
                            output_locations.source_for_site_generator.join('subnavs', '_dita_subnav_template.erb'),
                            output_locations.subnavs_for_layout_dir)
          end

          section_html_dir = output_locations.html_from_preprocessing_dir.join(dita_section.destination_directory)
          formatted_dir = output_locations.formatted_dir.join(dita_section.destination_directory)
          source_for_site_gen_dir = output_locations.source_for_site_generator.join(dita_section.destination_directory)

          dita_formatter.format_html section_html_dir, formatted_dir

          copy_images(dita_section.path_to_repository, formatted_dir)

          local_fs_accessor.copy_contents(formatted_dir, source_for_site_gen_dir)
        end
      end

      private

      attr_reader :dita_formatter, :local_fs_accessor, :command_creator, :sheller

      def convert_dita_files(section, command_creator, options, section_html_dir, sheller, output_streams)
        command = command_creator.convert_to_html_command(
          section,
          dita_flags: options,
          write_to: section_html_dir
        )
        status = sheller.run_command(command, output_streams.to_h)
        unless status.success?
          raise DitaToHtmlLibraryFailure.new 'The DITA-to-HTML conversion failed. ' +
                'Please check that you have specified the path to your DITA-OT library in the ENV, ' +
                'that your DITA-specific keys/values in config.yml are set, ' +
                'and that your DITA toolkit is correctly configured.'
        end
      end

      def generate_subnav(dita_section, output_locations, dita_subnav_template_path, subnavs_dir)
        dita_subnav_template_text = local_fs_accessor.read(dita_subnav_template_path)

        tocjs_text = local_fs_accessor.read(
          File.join(
            output_locations.html_from_preprocessing_dir.join(dita_section.destination_directory),
            'index.html')
        )
        json_props_location = json_props_location(dita_section.destination_directory)
        props_file_location = File.join(subnavs_dir, json_props_location)

        subnav = dita_formatter.format_subnav(dita_section.destination_directory,
                                              dita_subnav_template_text,
                                              json_props_location,
                                              tocjs_text)

        local_fs_accessor.write text: subnav.json_links, to: props_file_location

        local_fs_accessor.write text: subnav.text,
                                to: File.join(subnavs_dir, "#{dita_section.subnav_template}.erb")
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

      def json_props_location(section_dir)
        (["dita-subnav-props"] + Array(section_dir.to_s)).join("-") + ".json"
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
