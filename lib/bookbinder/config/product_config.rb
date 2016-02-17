require_relative '../config/topic_config'

module Bookbinder
  module Config
    class ProductConfig
      def initialize(config)
        @config = config
        @subnav_topics = assemble_topics || []
      end

      def id
        config['id']
      end

      def pdf_config
        config['pdf_config']
      end

      def subnav_exclusions
        config['subnav_exclusions'] || []
      end

      def specifies_subnav?
        !subnav_topics.empty?
      end

      def valid?
        (CONFIG_REQUIRED_KEYS - config.keys).empty?
      end

      CONFIG_REQUIRED_KEYS = %w(id subnav_topics)

      attr_reader :subnav_topics
      alias_method :subnav_name, :id

      private

      attr_reader :config

      def assemble_topics
        config['subnav_topics'].map{|topic| Config::TopicConfig.new(topic)} if config['subnav_topics']
      end
    end
  end
end

