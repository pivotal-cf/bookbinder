require_relative 'subnav_json_generator'

module Bookbinder
  module Preprocessing
    class SubnavGenerator
      def initialize(fs, output_locations)
        @fs = fs
        @output_locations = output_locations
        @json_generator = SubnavJsonGenerator.new
      end

      def generate(subnav_config)
        json_generator.get_links_from_config(subnav_config)
      end

      attr_reader :fs, :output_locations, :json_generator
    end
  end
end
