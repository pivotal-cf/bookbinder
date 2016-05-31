require_relative '../subnav/subnav_generator'
require_relative '../subnav/navigation_entries_from_markdown_root'

module Bookbinder
  module Preprocessing
    class LinkToSiteGenDir
      def initialize(filesystem, subnav_generator_factory)
        @filesystem = filesystem
        @subnav_generator_factory = subnav_generator_factory
      end

      def applicable_to?(section)
        filesystem.file_exist?(section.path_to_repo_dir)
      end

      def preprocess(sections, output_locations, config: nil, options: {}, **_)
        sections.each do |section|
          filesystem.link_creating_intermediate_dirs(
            section.path_to_repo_dir,
            output_locations.source_for_site_generator.join(section.destination_directory)
          )
        end

        generator = subnav_generator(options[:require_valid_subnav_links])
        config.products.each do |product|
          generator.generate(product)
        end
      end

      private

      def subnav_generator(require_valid_subnav_links)
        @subnav_generator ||= subnav_generator_factory.produce(Subnav::NavigationEntriesFromMarkdownRoot.new(filesystem, require_valid_subnav_links))
      end

      attr_reader :filesystem, :subnav_generator_factory
    end
  end
end
