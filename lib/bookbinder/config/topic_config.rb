module Bookbinder
  module Config
    class TopicConfig
      def initialize(config)
        @config = config
      end

      def title
        config['title']
      end

      def toc_url
        config['toc_url']
      end

      def valid?
        (CONFIG_REQUIRED_KEYS - config.keys).empty?
      end

      CONFIG_REQUIRED_KEYS = %w(title toc_url)

      attr_reader :config
    end
  end
end
