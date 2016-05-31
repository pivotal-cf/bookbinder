module Bookbinder
  module Subnav
    class SubnavGenerator
      def initialize(navigation_entries_parser, template_creator, pdf_config_creator, output_locations)
        @navigation_entries_parser = navigation_entries_parser
        @template_creator = template_creator
        @pdf_config_creator = pdf_config_creator
        @output_locations = output_locations
      end

      def generate(subnav_spec)
        navigation_entries = navigation_entries_parser.get_links(subnav_spec, output_locations)
        template_creator.create(navigation_entries, subnav_spec)
        pdf_config_creator.create(navigation_entries, subnav_spec) if pdf?(subnav_spec)
      end

      attr_reader :navigation_entries_parser, :template_creator, :pdf_config_creator

      private

      attr_reader :output_locations

      def pdf?(subnav_spec)
        subnav_spec.respond_to?(:pdf_config) && subnav_spec.pdf_config
      end
    end
  end
end
