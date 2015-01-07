module Bookbinder
  module Commands
    class BookbinderCommand
      def initialize(logger, configuration_fetcher)
        @logger = logger
        @configuration_fetcher = configuration_fetcher
      end

      private

      def config
        @config ||= configuration_fetcher.fetch_config
      end

      attr_reader :configuration_fetcher
    end
  end
end
