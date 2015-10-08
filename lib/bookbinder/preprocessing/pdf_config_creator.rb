require 'yaml'
require "json"

module Bookbinder
  module Preprocessing
    class PdfConfigCreator
      def initialize(fs, output_locations)
        @fs = fs
        @output_locations = output_locations
      end

      def create(props_filename, subnav_config)
        json = JSON.parse(fs.read(props_location(props_filename)))
        @links = format_links(json['links'])

        fs.write(to: output_locations.pdf_config_dir.join(subnav_config.pdf_config),
                 text: config_content)
      end

      attr_reader :fs, :output_locations

      private

      def props_location(filename)
        output_locations.subnavs_for_layout_dir.join(filename)
      end

      def format_links(links)
        links.map{|item| item['url'] }.compact.map{|link| link.sub(/^\//, '')}
      end

      def config_content
        config_keys.inject({}) do |hash, key|
          hash[key] = content_for(key)
          hash
        end.to_yaml
      end

      def config_keys
        %w{copyright_notice header executable pages}
      end

      def content_for(key)
        key == 'pages' ? @links : default_content
      end

      def default_content
        'REPLACE ME'
      end
    end
  end
end
