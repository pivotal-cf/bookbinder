require_relative '../commands/bind'
require_relative '../commands/build_and_push_tarball'
require_relative '../commands/generate_pdf'
require_relative '../commands/help'
require_relative '../commands/version'
require_relative '../local_dita_processor'
require_relative '../middleman_runner'
require_relative '../spider'

module Bookbinder
  module Repositories
    class CommandRepository
      include Enumerable

      def initialize(logger,
                     configuration_fetcher,
                     git_accessor,
                     local_file_system_accessor)
        @logger = logger
        @configuration_fetcher = configuration_fetcher
        @git_accessor = git_accessor
        @local_file_system_accessor = local_file_system_accessor
      end

      def each(&block)
        list.each(&block)
      end

      def help
        @help ||= Commands::Help.new(
          logger,
          [version] + standard_commands
        )
      end

      private

      attr_reader(:logger,
                  :configuration_fetcher,
                  :git_accessor,
                  :local_file_system_accessor)

      def list
        standard_commands + flags
      end

      def flags
        @flags ||= [ version, help ]
      end

      def standard_commands
        @standard_commands ||= [
          build_and_push_tarball,
          Commands::GeneratePDF.new(logger, configuration_fetcher),
          bind,
          push_local_to_staging,
          Commands::PushToProd.new(logger, configuration_fetcher),
          Commands::RunPublishCI.new(bind, push_local_to_staging, build_and_push_tarball),
          Commands::Tag.new(logger, configuration_fetcher),
          Commands::UpdateLocalDocRepos.new(logger, configuration_fetcher),
        ]
      end

      def version
        @version ||= Commands::Version.new(logger)
      end

      def bind
        @bind ||= Commands::Bind.new(
          logger,
          configuration_fetcher,
          git_accessor,
          local_file_system_accessor,
          middleman_runner,
          spider,
          final_app_directory,
          server_director,
          File.absolute_path('.'),
          local_dita_processor
        )
      end

      def push_local_to_staging
        @push_local_to_staging ||= Commands::PushLocalToStaging.new(
          logger,
          configuration_fetcher
        )
      end

      def build_and_push_tarball
        @build_and_push_tarball ||= Commands::BuildAndPushTarball.new(
          logger,
          configuration_fetcher
        )
      end

      def local_dita_processor
        @local_dita_processor ||=
          LocalDitaProcessor.new(Sheller.new(logger), configuration_fetcher)
      end

      def spider
        @spider ||= Spider.new(logger, app_dir: final_app_directory)
      end

      def server_director
        @server_director ||= ServerDirector.new(
          logger,
          directory: final_app_directory
        )
      end

      def middleman_runner
        @middleman_runner ||= MiddlemanRunner.new(logger, git_accessor)
      end

      def final_app_directory
        @final_app_directory ||= File.absolute_path('final_app')
      end
    end
  end
end
