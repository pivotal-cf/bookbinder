module Bookbinder
  class Cli
    class BookbinderCommand
      def initialize(logger, configuration)
        @logger = logger
        @config = configuration
      end

      private
      attr_accessor :config
    end
  end
end