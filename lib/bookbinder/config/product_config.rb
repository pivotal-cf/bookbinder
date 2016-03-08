module Bookbinder
  module Config
    class ProductConfig
      def initialize(config)
        @config = config
      end

      def id
        config['id']
      end

      def pdf_config
        config['pdf_config']
      end

      def subnav_root
        config['subnav_root']
      end

      def valid?
        (CONFIG_REQUIRED_KEYS - config.keys).empty?
      end

      CONFIG_REQUIRED_KEYS = %w(id)

      alias_method :subnav_name, :id

      private

      attr_reader :config
    end
  end
end

