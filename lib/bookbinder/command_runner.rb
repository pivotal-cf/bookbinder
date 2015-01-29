require_relative 'cli_error'
require_relative 'local_dita_processor'
require_relative 'sheller'

module Bookbinder
  class CommandRunner
    def initialize(configuration_fetcher,
                   usage_message,
                   logger,
                   version_control_system,
                   file_system_accessor,
                   static_site_generator,
                   sitemap_generator,
                   final_app_directory,
                   server_director,
                   commands)
      @configuration_fetcher = configuration_fetcher
      @usage_message = usage_message
      @logger = logger
      @version_control_system = version_control_system
      @file_system_accessor = file_system_accessor
      @static_site_generator = static_site_generator
      @sitemap_generator = sitemap_generator
      @final_app_directory = final_app_directory
      @server_director = server_director
      @commands = commands
    end

    def run(command_name, command_arguments)
      command = commands.detect { |known_command| known_command.command_name == command_name }
      begin
        if command_name == '--help'
          command.new(logger, usage_message).run command_arguments
        elsif command_name == 'publish'
          publish_command.run command_arguments
        elsif command_name == 'run_publish_ci'
          push_local_to_staging_command = Commands::PushLocalToStaging.new(logger, configuration_fetcher)
          build_and_push_tarball_command = Commands::BuildAndPushTarball.new(logger, configuration_fetcher)

          command.new(publish_command, push_local_to_staging_command, build_and_push_tarball_command).run command_arguments
        else
          command.new(logger, configuration_fetcher).run command_arguments
        end
      rescue CliError::InvalidArguments
        logger.log command.usage
        1
      end
    end

    private

    attr_reader :logger,
                :usage_message,
                :commands,
                :version_control_system,
                :configuration_fetcher,
                :static_site_generator,
                :file_system_accessor,
                :sitemap_generator,
                :final_app_directory,
                :server_director

    def publish_command
      config = configuration_fetcher.fetch_config
      sheller = Sheller.new(logger)
      local_dita_processor = LocalDitaProcessor.new(sheller, config.path_to_dita_ot_library)

      Commands::Publish.new(logger,
                            configuration_fetcher.fetch_config,
                            version_control_system,
                            file_system_accessor,
                            static_site_generator,
                            sitemap_generator,
                            final_app_directory,
                            server_director,
                            File.absolute_path('.'),
                            local_dita_processor)
    end

  end
end

