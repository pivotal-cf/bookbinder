Dir.glob(File.expand_path('../../commands/*.rb', __FILE__)).each do |command_file|
  require command_file
end

require_relative '../commands/bind/directory_preparer'
require_relative '../config/archive_menu_configuration'
require_relative '../config/fetcher'
require_relative '../config/remote_yaml_credential_provider'
require_relative '../config/validator'
require_relative '../config/yaml_loader'
require_relative '../dita_command_creator'
require_relative '../dita_html_to_middleman_formatter'
require_relative '../html_document_manipulator'
require_relative '../ingest/cloner_factory'
require_relative '../ingest/section_repository'
require_relative '../local_filesystem_accessor'
require_relative '../middleman_runner'
require_relative '../postprocessing/sitemap_writer'
require_relative '../preprocessing/dita_preprocessor'
require_relative '../preprocessing/link_to_site_gen_dir'
require_relative '../preprocessing/preprocessor'
require_relative '../subnav/subnav_generator_factory'
require_relative '../sheller'
require_relative '../subnav/json_from_html'
require_relative '../values/output_locations'

module Bookbinder
  module Commands
    class Collection
      include Enumerable

      def initialize(logger, streams, version_control_system)
        @logger = logger
        @streams = streams
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

      attr_reader :logger, :streams, :version_control_system

      def list
        standard_commands + flags
      end

      def flags
        @flags ||= [ version, help ]
      end

      def standard_commands
        @standard_commands ||= [
          Commands::Generate.new(
            local_filesystem_accessor,
            sheller,
            Dir.pwd,
            streams
          ),
          build_and_push_tarball,
          bind,
          Commands::PushFromLocal.new(streams, logger, configuration_fetcher, 'acceptance'),
          push_local_to_staging,
          Commands::PushToProd.new(streams, logger, configuration_fetcher, Dir.mktmpdir),
          Commands::RunPublishCI.new(bind, push_local_to_staging, build_and_push_tarball),
          Commands::UpdateLocalDocRepos.new(
            streams,
            configuration_fetcher,
            version_control_system
          ),
          watch
        ]
      end

      def version
        @version ||= Commands::Version.new(logger)
      end

      def bind
        @bind ||= Commands::Bind.new(
          streams,
          output_locations,
          configuration_fetcher,
          Config::ArchiveMenuConfiguration.new(loader: config_loader, config_filename: 'bookbinder.yml'),
          local_filesystem_accessor,
          runner,
          Postprocessing::SitemapWriter.build(logger, final_app_directory, sitemap_port),
          Preprocessing::Preprocessor.new(
            Preprocessing::DitaPreprocessor.new(
              DitaHtmlToMiddlemanFormatter.new(local_filesystem_accessor, dita_json_generator, html_document_manipulator),
              local_filesystem_accessor,
              DitaCommandCreator.new(ENV['PATH_TO_DITA_OT_LIBRARY']),
              sheller
            ),
            Preprocessing::LinkToSiteGenDir.new(local_filesystem_accessor, subnav_generator_factory)
          ),
          Ingest::ClonerFactory.new(streams, local_filesystem_accessor, version_control_system),
          Ingest::SectionRepository.new,
          directory_preparer
        )
      end

      def watch
        @watch ||= Commands::Watch.new(
          streams,
          middleman_runner: runner,
          output_locations: output_locations,
          config_fetcher: configuration_fetcher,
          config_decorator: Config::ArchiveMenuConfiguration.new(loader: config_loader, config_filename: 'bookbinder.yml'),
          file_system_accessor: local_filesystem_accessor,
          preprocessor: Preprocessing::Preprocessor.new(Preprocessing::LinkToSiteGenDir.new(local_filesystem_accessor, subnav_generator_factory)),
          cloner: local_file_system_cloner,
          section_repository: Ingest::SectionRepository.new,
          directory_preparer: directory_preparer
        )
      end

      def push_local_to_staging
        @push_local_to_staging ||= Commands::PushFromLocal.new(
          streams,
          logger,
          configuration_fetcher,
          'staging'
        )
      end

      def build_and_push_tarball
        @build_and_push_tarball ||= Commands::BuildAndPushTarball.new(
          streams,
          configuration_fetcher
        )
      end

      def configuration_fetcher
        @configuration_fetcher ||= Config::Fetcher.new(
          Config::Validator.new(local_filesystem_accessor),
          config_loader,
          Config::RemoteYamlCredentialProvider.new(logger, version_control_system)
        ).tap do |fetcher|
          fetcher.set_config_file_path './config.yml'
          fetcher.set_config_dir_path './config/'
        end
      end

      def config_loader
        @config_loader ||= Config::YAMLLoader.new
      end

      def subnav_generator_factory
        Subnav::SubnavGeneratorFactory.new(local_filesystem_accessor, output_locations)
      end

      def json_generator
        Subnav::JsonFromConfig.new
      end

      def directory_preparer
        Commands::BindComponents::DirectoryPreparer.new(local_filesystem_accessor)
      end

      def output_locations
        OutputLocations.new(final_app_dir: final_app_directory, context_dir: File.absolute_path('.'))
      end

      def final_app_directory
        @final_app_directory ||= File.absolute_path('final_app')
      end

      def dita_json_generator
        Subnav::JsonFromHtml.new
      end

      def html_document_manipulator
        @html_document_manipulator ||= HtmlDocumentManipulator.new
      end

      def local_filesystem_accessor
        @local_filesystem_accessor ||= LocalFilesystemAccessor.new
      end

      def sheller
        @sheller ||= Sheller.new
      end

      def sitemap_port
        41722
      end

      def runner
        MiddlemanRunner.new(local_filesystem_accessor, sheller)
      end

      def local_file_system_cloner
        Ingest::LocalFilesystemCloner.new(streams, local_filesystem_accessor, File.expand_path('..'))
      end
    end
  end
end
