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

      def in_usage_order
        [
          build_and_push_tarball,
          generate_pdf,
          bind,
          push_local_to_staging,
          push_to_prod,
          run_publish_ci,
          tag,
          update_local_doc_repos
        ]
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
          build_and_push_tarball,
          generate_pdf,
          bind,
          push_local_to_staging,
          push_to_prod,
          run_publish_ci,
          tag,
          update_local_doc_repos
      ]
      end

      def build_and_push_tarball
        @build_and_push_tarball ||= Commands::BuildAndPushTarball.new(
          logger,
          configuration_fetcher
        )
      end

      def generate_pdf
        @generate_pdf ||= Commands::GeneratePDF.new(
          logger,
          configuration_fetcher
        )
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

      def push_to_prod
        @push_to_prod ||= Commands::PushToProd.new(
          logger,
          configuration_fetcher
        )
      end

      def run_publish_ci
        @run_publish_ci ||= Commands::RunPublishCI.new(
          bind,
          push_local_to_staging,
          build_and_push_tarball
        )
      end

      def tag
        @tag ||= Commands::Tag.new(logger, configuration_fetcher)
      end

      def update_local_doc_repos
        @update_local_doc_repos ||= Commands::UpdateLocalDocRepos.new(
          logger,
          configuration_fetcher
        )
      end
    end
  end
end
