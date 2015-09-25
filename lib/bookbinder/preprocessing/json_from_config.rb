require 'json'

module Bookbinder
  module Preprocessing
    class JsonFromConfig
      def get_links(subnav_config)
        { links: get_titles_from(subnav_config) }.to_json
      end

      private

      def get_titles_from(config)
        config.topics.map do |topic|
          { text: topic['title'] }
        end
      end
    end
  end
end
