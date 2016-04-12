require_relative '../command_runner'
require_relative '../commands/collection'
require_relative '../streams/colorized_stream'
require_relative '../terminal'
require_relative '../deprecated_logger'

module Bookbinder
  module Legacy
    class Cli
      def initialize(version_control_system)
        @version_control_system = version_control_system
      end

      def run(args)
        command_name, *command_arguments = args

        logger = DeprecatedLogger.new
        commands = Bookbinder::Commands::Collection.new(
          logger,
          colorized_streams,
          version_control_system
        )

        command_runner = CommandRunner.new(logger, commands)

        begin
          command_runner.run(command_name, command_arguments)

        rescue KeyError => e
          colorized_streams[:err].puts "#{e.message} from your configuration."
          1
        rescue RuntimeError => e
          colorized_streams[:err].puts e.message
          1
        end
      end

      private

      attr_reader :version_control_system

      def colorized_streams
        {
          err: Streams::ColorizedStream.new(Colorizer::Colors.red, $stderr),
          out: $stdout,
          success: Streams::ColorizedStream.new(Colorizer::Colors.green, $stdout),
          warn: Streams::ColorizedStream.new(Colorizer::Colors.yellow, $stdout),
        }
      end
    end
  end
end
