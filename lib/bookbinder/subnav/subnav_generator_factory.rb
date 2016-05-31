require_relative 'template_creator'
require_relative 'pdf_config_creator'

module Bookbinder
  module Subnav
    class SubnavGeneratorFactory
      def initialize(fs, output_locations)
        @fs = fs
        @output_locations = output_locations
      end

      def produce(json_generator)
        SubnavGenerator.new(json_generator, template_creator, pdf_config_creator, output_locations)
      end

      attr_reader :fs, :output_locations

      private

      def template_creator
        @template_creator ||= TemplateCreator.new(fs, output_locations)
      end

      def pdf_config_creator
        @pdf_config_creator ||= PdfConfigCreator.new(fs, output_locations)
      end
    end
  end
end
