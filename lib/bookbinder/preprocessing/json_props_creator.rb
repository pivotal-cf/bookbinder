module Bookbinder
  module Preprocessing
    class JsonPropsCreator
      def initialize(fs, output_locations, json_generator)
        @fs = fs
        @output_locations = output_locations
        @json_generator = json_generator
      end

      def create(subnav_config)
        json_links = json_generator.get_links(subnav_config, output_locations.source_for_site_generator)

        fs.write(text: json_links, to: props_path(subnav_config.name))

        filename(subnav_config.name)
      end

      attr_reader :fs, :output_locations, :json_generator

      private

      def filename(name)
        "#{name}-props.json"
      end

      def subnavs_path
        output_locations.subnavs_for_layout_dir
      end

      def props_path(name)
        subnavs_path.join(filename(name))
      end
    end
  end
end
