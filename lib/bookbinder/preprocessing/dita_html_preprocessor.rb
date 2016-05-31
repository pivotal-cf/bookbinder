require_relative '../values/subnav_template'
require_relative '../../../lib/bookbinder/subnav/navigation_entries_from_html_toc'

module Bookbinder
  module Preprocessing
    class DitaHTMLPreprocessor
      DitaToHtmlLibraryFailure = Class.new(RuntimeError)

      ACCEPTED_IMAGE_FORMATS = %w(png jpeg jpg svg gif bmp tif tiff eps)

      def initialize(fs, subnav_gen_factory, dita_formatter, command_creator, sheller)
        @fs = fs
        @subnav_gen_factory = subnav_gen_factory
        @dita_formatter = dita_formatter
        @command_creator = command_creator
        @sheller = sheller
      end

      def applicable_to?(section)
        section.subnav_template.include?('dita_subnav') if section.subnav_template
      end

      def preprocess(sections, output_locations, options: {}, output_streams: nil, **_)
        @output_locations = output_locations

        sections.each do |section|
          if section.path_to_preprocessor_attribute('ditamap_location')
            convert_dita_files(section,
                               command_creator,
                               options[:dita_flags],
                               section_html_dir(section),
                               sheller,
                               output_streams)

            subnav_generator.generate(section)
          end

          dita_formatter.format_html(section_html_dir(section), formatted_dir(section))
          copy_images(section.path_to_repo_dir, formatted_dir(section))
          fs.copy_contents(formatted_dir(section), source_for_site_gen_dir(section))
        end
      end

      private

      attr_reader :fs, :subnav_gen_factory, :dita_formatter, :command_creator, :sheller, :output_locations

      def section_html_dir(section)
        output_locations.html_from_preprocessing_dir.join(section.destination_directory)
      end

      def formatted_dir(section)
        output_locations.formatted_dir.join(section.destination_directory)
      end

      def source_for_site_gen_dir(section)
        output_locations.source_for_site_generator.join(section.destination_directory)
      end

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

      def copy_images(src, dest)
        image_paths = ACCEPTED_IMAGE_FORMATS.map do |format|
          fs.find_files_with_ext(format, src)
        end.flatten

        image_paths.each do |image_path|
          fs.copy_including_intermediate_dirs(image_path, src, dest)
        end
      end


      def subnav_generator
        @subnav_generator ||= subnav_gen_factory.produce(Subnav::NavigationEntriesFromHtmlToc.new(fs))
      end
    end
  end
end
