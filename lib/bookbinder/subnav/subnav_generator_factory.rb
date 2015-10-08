require_relative 'json_props_creator'
require_relative 'template_creator'
require_relative 'pdf_config_creator'
require_relative '../html_document_manipulator'

module Bookbinder
  module Subnav
    class SubnavGeneratorFactory
      def initialize(fs, output_locations)
        @fs = fs
        @output_locations = output_locations
      end

      def produce(json_generator)
        SubnavGenerator.new(json_props_creator(json_generator), template_creator, pdf_config_creator)
      end

      attr_reader :fs, :output_locations

      private

      def json_props_creator(json_generator)
        @json_props_creator ||= JsonPropsCreator.new(fs, output_locations, json_generator)
      end

      def template_creator
        @template_creator ||= TemplateCreator.new(fs, output_locations, HtmlDocumentManipulator.new)
      end

      def pdf_config_creator
        @pdf_config_creator ||= PdfConfigCreator.new(fs, output_locations)
      end
    end
  end
end
