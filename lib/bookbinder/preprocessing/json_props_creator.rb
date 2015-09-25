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

        fs.write(text: json_links, to: full_path_to_props(subnav_config.name))

        props_path
      end

      attr_reader :fs, :output_locations, :json_generator, :props_path

      private

      def subnavs_path
        output_locations.subnavs_for_layout_dir
      end

      def filename(name)
        "#{name}-subnav-props.json"
      end

      def full_path_to_props(name)
        @props_path ||= subnavs_path.join(filename(name))
      end
    end
  end
end
