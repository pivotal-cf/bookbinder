require_relative 'remote_bind_configuration'

module Bookbinder
  module Config
    class BindConfigFactory
      def initialize(logger, version_control_system, config_fetcher)
        @logger = logger
        @version_control_system = version_control_system
        @config_fetcher = config_fetcher
      end

      def produce(bind_source)
        if bind_source == 'remote' && config.has_option?('versions')
          RemoteBindConfiguration.new(version_control_system, config).fetch
        else
          config
        end
      end

      private

      def config
        config_fetcher.fetch_config
      end

      attr_reader :logger, :version_control_system, :config_fetcher
    end
  end
end
