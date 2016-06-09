module Bookbinder
  module Preprocessing
    class DitaPDFPreprocessor
      DitaToPDFLibraryFailure = Class.new(RuntimeError)

      def initialize(fs, command_creator, sheller)
        @fs = fs
        @command_creator = command_creator
        @sheller = sheller
      end

      def applicable_to?(section)
        !!section.pdf_output_filename
      end

      def preprocess(sections, output_locations, options: {}, output_streams: nil, **_)
        sections.each do |section|
          command = command_creator.convert_to_pdf_command(
            section,
            dita_flags: options[:dita_flags],
            write_to: output_locations.pdf_from_preprocessing_dir
          )
          status = sheller.run_command(command, output_streams.to_h)

          if status.success?
            pdf_path = most_recent_pdf(output_locations.pdf_from_preprocessing_dir)
            pdf_destination = output_locations.pdf_artifact_dir.join(section.pdf_output_filename)
            fs.copy_and_rename(pdf_path, pdf_destination)
          else
            raise DitaToPDFLibraryFailure.new 'The DITA-to-PDF conversion failed. ' +
              'Please check that you have specified the path to your DITA-OT library in the ENV, ' +
              'that your DITA-specific keys/values in config.yml are set, ' +
              'and that your DITA toolkit is correctly configured.'
          end
        end
      end

      def most_recent_pdf(dir_path)
        pdfs_by_modified_date = Dir.glob(dir_path + '**/*.pdf').sort_by{ |f| File.mtime(f) }
        pdfs_by_modified_date.last
      end

      private

      attr_reader :command_creator, :sheller, :fs
    end
  end
end
