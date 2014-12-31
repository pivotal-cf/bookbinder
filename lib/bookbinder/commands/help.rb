module Bookbinder
  module Commands
    class Help
      def initialize(logger, usage_message)
        @logger = logger
        @usage_message = usage_message
      end

      def self.to_s
        'help'
      end

      def self.command_name
        '--help'
      end

      def self.usage
        "--help \t \t \t \t \t Print this message"
      end

      def run(*)
        logger.log(usage_message)
        0
      end

      private

      attr_reader :logger, :usage_message
    end
  end
end
