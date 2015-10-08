require_relative '../subnav/subnav_generator'
require_relative '../subnav/json_from_config'

module Bookbinder
  module Preprocessing
    class LinkToSiteGenDir
      def initialize(filesystem, subnav_generator_factory)
        @filesystem = filesystem
        @subnav_generator_factory = subnav_generator_factory
      end

      def applicable_to?(section)
        filesystem.file_exist?(section.path_to_repository)
      end

      def preprocess(sections, output_locations, config: nil, **_)
        sections.each do |section|
          filesystem.link_creating_intermediate_dirs(
            section.path_to_repository,
            output_locations.source_for_site_generator.join(section.destination_directory)
          )
        end

        config.subnavs.each do |subnav|
          subnav_generator.generate(subnav)
        end
      end

      private

      def subnav_generator
        @subnav_generator ||= subnav_generator_factory.produce(Subnav::JsonFromConfig.new(filesystem))
      end

      attr_reader :filesystem, :subnav_generator_factory
    end
  end
end
