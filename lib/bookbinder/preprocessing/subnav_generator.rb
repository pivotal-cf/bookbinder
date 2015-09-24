module Bookbinder
  module Preprocessing
    class SubnavGenerator
      def initialize(fs, output_locations)
        @fs = fs
        @output_locations = output_locations
      end

      def generate(subnav_config)

      end

      attr_reader :fs, :output_locations
    end
  end
end
