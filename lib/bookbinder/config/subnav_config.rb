require_relative '../config/topic_config'

module Bookbinder
  module Config
    class SubnavConfig
      def initialize(config)
        @config = config
        @topics = assemble_topics || []
      end

      def subnav_name
        config['name']
      end

      def pdf_config
        config['pdf_config']
      end

      def subnav_exclusions
        config['subnav_exclusions'] || []
      end

      def valid?
        (CONFIG_REQUIRED_KEYS - config.keys).empty?
      end

      CONFIG_REQUIRED_KEYS = %w(name topics)

      attr_reader :topics

      private

      attr_reader :config

      def assemble_topics
        config['topics'].map{|topic| Config::TopicConfig.new(topic)} if config['topics']
      end
    end
  end
end

