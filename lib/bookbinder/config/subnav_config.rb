module Bookbinder
  module Config
    class SubnavConfig
      def initialize(config)
        @config = config
      end

      def name
        config['name']
      end

      def topics
        config['topics'] || []
      end

      def valid?
        (CONFIG_REQUIRED_KEYS - config.keys).empty?
      end

      CONFIG_REQUIRED_KEYS = %w(name topics)

      attr_reader :config
    end
  end
end

