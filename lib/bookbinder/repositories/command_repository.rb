Dir.glob(File.expand_path('../../commands/*.rb', __FILE__)).each do |command_file|
  require command_file
end
require_relative '../config/bind_config_factory'
require_relative '../configuration_fetcher'
require_relative '../configuration_validator'
require_relative '../dita_command_creator'
require_relative '../dita_html_to_middleman_formatter'
require_relative '../dita_preprocessor'
require_relative '../html_document_manipulator'
require_relative '../ingest/cloner_factory'
require_relative '../local_file_system_accessor'
require_relative '../middleman_runner'
require_relative '../post_production/sitemap_writer'
require_relative '../sheller'
require_relative '../subnav_formatter'
require_relative '../yaml_loader'

module Bookbinder
  module Repositories
    class CommandRepository
      include Enumerable

      def initialize(logger, version_control_system)
        @logger = logger
        @version_control_system = version_control_system
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

      attr_reader :logger, :version_control_system

      def list
        standard_commands + flags
      end

      def flags
        @flags ||= [ version, help ]
      end

      def standard_commands
        @standard_commands ||= [
          build_and_push_tarball,
          bind,
          Commands::PushFromLocal.new(logger, configuration_fetcher, 'acceptance'),
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
          bind_config_factory,
          ArchiveMenuConfiguration.new(
            loader: config_loader,
            config_filename: 'bookbinder.yml'
          ),
          version_control_system,
          local_file_system_accessor,
          middleman_runner,
          PostProduction::SitemapWriter.build(logger, final_app_directory, sitemap_port),
          final_app_directory,
          File.absolute_path('.'),
          dita_preprocessor,
          Ingest::ClonerFactory.new(logger, version_control_system),
          DitaSectionGathererFactory.new(version_control_system, logger),
          Repositories::SectionRepository.new(logger),
          local_dita_processor,
          Sheller.new(logger)
        )
      end

      def push_local_to_staging
        @push_local_to_staging ||= Commands::PushFromLocal.new(
          logger,
          configuration_fetcher,
          'staging'
        )
      end

      def build_and_push_tarball
        @build_and_push_tarball ||= Commands::BuildAndPushTarball.new(
          logger,
          configuration_fetcher
        )
      end

      def middleman_runner
        @middleman_runner ||= MiddlemanRunner.new(logger, version_control_system)
      end

      def configuration_fetcher
        @configuration_fetcher ||= ConfigurationFetcher.new(
          logger,
          ConfigurationValidator.new(logger, local_file_system_accessor),
          config_loader
        ).tap do |fetcher|
          fetcher.set_config_file_path './config.yml'
        end
      end

      def config_loader
        @config_loader ||= YAMLLoader.new
      end

      def final_app_directory
        @final_app_directory ||= File.absolute_path('final_app')
      end

      def dita_preprocessor
        @dita_preprocessor ||=
            DitaPreprocessor.new(dita_html_to_middleman_formatter,
                                 local_file_system_accessor)
      end

      def local_dita_processor
        @local_dita_processor ||= DitaCommandCreator.new(ENV['PATH_TO_DITA_OT_LIBRARY'])
      end

      def dita_html_to_middleman_formatter
        @dita_html_to_middleman_formatter ||= DitaHtmlToMiddlemanFormatter.new(local_file_system_accessor,
                                                                               subnav_formatter,
                                                                               html_document_manipulator)
      end

      def subnav_formatter
        @subnav_formatter ||= SubnavFormatter.new
      end

      def html_document_manipulator
        @html_document_manipulator ||= HtmlDocumentManipulator.new
      end

      def local_file_system_accessor
        @local_file_system_accessor ||= LocalFileSystemAccessor.new
      end

      def bind_config_factory
        @bind_config_factory  ||= Config::BindConfigFactory.new(logger, version_control_system, configuration_fetcher)
      end

      def sitemap_port
        41722
      end
    end
  end
end
