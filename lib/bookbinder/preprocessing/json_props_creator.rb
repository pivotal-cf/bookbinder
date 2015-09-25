module Bookbinder
  module Preprocessing
    class JsonPropsCreator
      def initialize(fs, output_locations, json_generator)
        @fs = fs
        @output_locations = output_locations
        @json_generator = json_generator
      end

      def create(subnav_config)
        json_links = json_generator.generate(subnav_config)

        fs.write(text: json_links, to: props_path(subnav_config.name))

        filename
      end

      attr_reader :fs, :output_locations, :json_generator, :filename

      private

      def subnavs_path
        output_locations.subnavs_for_layout_dir
      end

      def set_filename(name)
        @filename ||= "#{name}-subnav-props.json"
      end

      def props_path(name)
        subnavs_path.join(set_filename(name))
      end
    end
  end
end
