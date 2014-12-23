module Bookbinder
  class Cli
    class BookbinderCommand
      def initialize(logger, configuration_fetcher)
        @logger = logger
        @configuration_fetcher = configuration_fetcher
        @config = configuration_fetcher.fetch_config
      end

      private
      attr_accessor :config, :configuration_fetcher
    end
  end
end