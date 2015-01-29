require_relative 'naming'

module Bookbinder
  module Commands
    class Help
      include Commands::Naming

      attr_writer :usage_message

      def initialize(logger)
        @logger = logger
      end

      def self.to_s
        'help'
      end

      def command_name
        '--help'
      end

      def usage
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
