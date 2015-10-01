require_relative '../config/topic_config'

module Bookbinder
  module Config
    class SubnavConfig
      def initialize(config)
        @config = config
        @topics = assemble_topics || []
      end

      def name
        config['name']
      end

      def valid?
        (CONFIG_REQUIRED_KEYS - config.keys).empty?
      end

      CONFIG_REQUIRED_KEYS = %w(name topics)

      attr_reader :config, :topics

      private

      def assemble_topics
        config['topics'].map{|topic| Config::TopicConfig.new(topic)} if config['topics']
      end
    end
  end
end

