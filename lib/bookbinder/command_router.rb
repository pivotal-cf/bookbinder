module Bookbinder
  class CommandRouter
    def initialize(configuration_fetcher, usage_messenger, logger, flags)
      @configuration_fetcher = configuration_fetcher
      @usage_messenger = usage_messenger
      @logger = logger
      @flags = flags
    end

    def route(command_name, command, command_arguments)
      if command_name && command_name.match(/^--/)
        flag = command_name[2..-1]
        if flags.include? flag
          self.send flag
        else
          unrecognized_flag(flag)
        end
        0
      elsif command
        run_command(command, command_arguments)
      else
        unrecognized_command command_name
      end
    end

    private

    attr_reader :usage_messenger, :logger, :flags

    def version
      logger.log "bookbinder #{Gem::Specification::load(File.join GEM_ROOT, "bookbinder.gemspec").version}"
    end

    def run_command(command, command_arguments)
      command.new(logger, @configuration_fetcher).run command_arguments
    rescue VersionUnsupportedError => e
      logger.error "config.yml at version '#{e.message}' has an unsupported API."
      1
    rescue Configuration::CredentialKeyError => e
      logger.error "#{e.message}, in credentials.yml"
      1
    rescue KeyError => e
      logger.error "#{e.message} from your configuration."
      1
    rescue Cli::InvalidArguments
      logger.log command.usage
      1
    rescue => e
      logger.error e.message
      1
    end

    def unrecognized_flag(name)
      logger.log "Unrecognized flag '--#{name}'"
      usage_messenger.print
    end

    def unrecognized_command(name)
      logger.log "Unrecognized command '#{name}'"
      usage_messenger.print
    end

  end
end

