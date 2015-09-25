module Bookbinder
  module Preprocessing
    class SubnavGenerator
      def initialize(json_props_creator, template_creator)
        @json_props_creator = json_props_creator
        @template_creator = template_creator
      end

      def generate(subnav_config)
        filename = json_props_creator.create(subnav_config)
        template_creator.create(filename, subnav_config)
      end

      attr_reader :json_props_creator, :template_creator
    end
  end
end
