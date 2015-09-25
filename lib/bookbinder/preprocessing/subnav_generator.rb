require_relative 'subnav_json_generator'
require_relative 'subnav_template_generator'

module Bookbinder
  module Preprocessing
    class SubnavGenerator
      def initialize(json_props_creator, template_creator)
        @json_props_creator = json_props_creator
        @template_creator = template_creator
      end

      def generate(toc_spec)
        location = json_props_creator.create(toc_spec)
        template_creator.create(location)
      end

      attr_reader :json_props_creator, :template_creator
    end
  end
end
