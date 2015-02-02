module Bookbinder
  module Repositories
    class CommandRepository
      def initialize(logger,
                     configuration_fetcher,
                     git_accessor,
                     local_file_system_accessor,
                     middleman_runner,
                     spider,
                     final_app_directory,
                     server_director,
                     local_dita_processor)
        @logger = logger
        @configuration_fetcher = configuration_fetcher
        @git_accessor = git_accessor
        @local_file_system_accessor = local_file_system_accessor
        @middleman_runner = middleman_runner
        @spider = spider
        @final_app_directory = final_app_directory
        @server_director = server_director
        @local_dita_processor = local_dita_processor
      end

      def each(&block)
        list.each(&block)
      end

      def +(other)
        list + other
      end

      private

      attr_reader(:logger,
                  :configuration_fetcher,
                  :git_accessor,
                  :local_file_system_accessor,
                  :middleman_runner,
                  :spider,
                  :final_app_directory,
                  :server_director,
                  :local_dita_processor)

      def list
        @list ||= [
          build_and_push_tarball_command = Commands::BuildAndPushTarball.new(logger, configuration_fetcher),
          Commands::GeneratePDF.new(logger, configuration_fetcher),
          bind_command = Commands::Bind.new(logger,
                                            configuration_fetcher,
                                            git_accessor,
                                            local_file_system_accessor,
                                            middleman_runner,
                                            spider,
                                            final_app_directory,
                                            server_director,
                                            File.absolute_path('.'),
                                            local_dita_processor),
          push_local_to_staging_command = Commands::PushLocalToStaging.new(logger, configuration_fetcher),
          Commands::PushToProd.new(logger, configuration_fetcher),
          Commands::RunPublishCI.new(bind_command,
                                     push_local_to_staging_command,
                                     build_and_push_tarball_command),
          Commands::Tag.new(logger, configuration_fetcher),
          Commands::UpdateLocalDocRepos.new(logger, configuration_fetcher),
      ]
      end
    end
  end
end
