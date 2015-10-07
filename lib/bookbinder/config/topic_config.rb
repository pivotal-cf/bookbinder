module Bookbinder
  module Config
    class TopicConfig
      def initialize(config)
        @config = config
      end

      def title
        config['title']
      end

      def toc_path
        Pathname(config['toc_path'])
      end

      def toc_nav_name
        config['toc_nav_name'] || title
      end

      def valid?
        (CONFIG_REQUIRED_KEYS - config.keys).empty?
      end

      CONFIG_REQUIRED_KEYS = %w(title toc_path)

      attr_reader :config
    end
  end
end
