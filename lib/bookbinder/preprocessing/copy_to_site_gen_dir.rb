module Bookbinder
  module Preprocessing
    class CopyToSiteGenDir
      def initialize(filesystem)
        @filesystem = filesystem
      end

      def applicable_to?(section)
        filesystem.file_exist?(section.path_to_repository)
      end

      def preprocess(sections, output_locations, *_)
        sections.each do |section|
          filesystem.copy_contents(
            section.path_to_repository,
            output_locations.source_for_site_generator.join(section.desired_directory)
          )
        end
      end

      private

      attr_reader :filesystem
    end
  end
end
