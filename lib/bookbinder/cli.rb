require_relative 'command_runner'
require_relative 'command_validator'
require_relative 'commands/collection'
require_relative 'config/cf_credentials'
require_relative 'streams/colorized_stream'
require_relative 'terminal'

module Bookbinder
  class Cli
    def initialize(version_control_system)
      @version_control_system = version_control_system
    end

    def run(args)
      command_name, *command_arguments = args

      logger = DeprecatedLogger.new
      commands = Commands::Collection.new(
        logger,
        colorized_streams,
        version_control_system
      )

      command_validator = CommandValidator.new(commands, commands.help.usage_message)
      command_runner = CommandRunner.new(logger, commands)
      command_name = command_name ? command_name : '--help'

      colorizer = Colorizer.new
      terminal = Terminal.new(colorizer)

      user_message = command_validator.validate(command_name)
      terminal.update(user_message)

      if user_message.error?
        return 1
      end

      begin
        command_runner.run command_name, command_arguments

      rescue Config::RemoteBindConfiguration::VersionUnsupportedError => e
        colorized_streams[:err].puts "config.yml at version '#{e.message}' has an unsupported API."
        1
      rescue Config::CfCredentials::CredentialKeyError => e
        colorized_streams[:err].puts "#{e.message}, in credentials.yml"
        1
      rescue KeyError => e
        colorized_streams[:err].puts "#{e.message} from your configuration."
        1
      rescue CliError::UnknownCommand => e
        colorized_streams[:out].puts e.message
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
