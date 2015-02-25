require_relative 'naming'

module Bookbinder
  module Commands
    class Help
      include Commands::Naming

      def initialize(logger, other_commands)
        @logger = logger
        @other_commands = other_commands
      end

      def usage
        [command_name, "Print this message"]
      end

      def run(*)
        logger.log(usage_message)
        0
      end

      def usage_message
        [usage_header, command_usage_messages].join("\n")
      end

      private

      def command_name
        '--help'
      end

      def command_usage_messages
        (flags + standard_commands).reduce('') { |message, command|
          "#{message}#{usage_indent}#{formatted_usage(command)}\n"
        }
      end

      def formatted_usage(command)
        "#{command.usage[0].ljust(chars_for_usage_definition)}#{command.usage[1]}"
      end

      def usage_indent
        " " * 4
      end

      def chars_for_usage_definition
        33
      end

      def flags
        other_commands.select(&:flag?) + [self]
      end

      def standard_commands
        other_commands.reject(&:flag?)
      end

      def usage_header
        <<TEXT

  \e[1;39;49mDocumentation\e[0m: https://github.com/pivotal-cf/docs-bookbinder

  \e[1;39;49mUsage\e[0m: bookbinder <command|flag> [args]
TEXT
      end

      attr_reader :logger, :other_commands
    end
  end
end
