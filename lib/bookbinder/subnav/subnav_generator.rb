module Bookbinder
  module Subnav
    class SubnavGenerator
      def initialize(json_props_creator, template_creator, pdf_config_creator)
        @json_props_creator = json_props_creator
        @template_creator = template_creator
        @pdf_config_creator = pdf_config_creator
      end

      def generate(subnav_spec)
        filename = json_props_creator.create(subnav_spec)
        template_creator.create(filename, subnav_spec)
        pdf_config_creator.create(filename, subnav_spec) if pdf?(subnav_spec)
      end

      attr_reader :json_props_creator, :template_creator, :pdf_config_creator

      private

      def pdf?(subnav_spec)
        subnav_spec.respond_to?(:pdf_config) && subnav_spec.pdf_config
      end
    end
  end
end
