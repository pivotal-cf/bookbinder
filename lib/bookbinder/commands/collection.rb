Dir.glob(File.expand_path('../../commands/*.rb', __FILE__)).each do |command_file|
  require command_file unless command_file =~ /collection\.rb\z/
end

require_relative '../commands/components/bind/directory_preparer'
require_relative '../commands/components/imprint/directory_preparer'
require_relative '../config/configuration_decorator'
require_relative '../config/fetcher'
require_relative '../config/validator'
require_relative '../config/yaml_loader'
require_relative '../config/configuration'
require_relative '../config/imprint/configuration'
require_relative '../dita_command_creator'
require_relative '../dita_html_for_middleman_formatter'
require_relative '../html_document_manipulator'
require_relative '../ingest/cloner_factory'
require_relative '../ingest/section_repository'
require_relative '../local_filesystem_accessor'
require_relative '../middleman_runner'
require_relative '../postprocessing/link_checker'
require_relative '../preprocessing/dita_html_preprocessor'
require_relative '../preprocessing/dita_pdf_preprocessor'
require_relative '../preprocessing/link_to_site_gen_dir'
require_relative '../preprocessing/preprocessor'
require_relative '../subnav/subnav_generator_factory'
require_relative '../sheller'
require_relative '../values/output_locations'

module Bookbinder
  module Commands
    class Collection
      include Enumerable

      def initialize(streams, version_control_system)
        @streams = streams
        @version_control_system = version_control_system
      end

      def generate(*args)
        Commands::Generate.new(
          local_filesystem_accessor,
          sheller,
          Dir.pwd,
          streams
        ).run(*args)
      end

      def punch(*args)
        Commands::Punch.new(
          streams,
          configuration_fetcher(Config::Configuration),
          version_control_system
        ).run(*args)
      end

      def update_local_doc_repos
        Commands::UpdateLocalDocRepos.new(
          streams,
          configuration_fetcher(Config::Configuration),
          version_control_system
        ).run
      end

      def bind(*args)
        @bind ||= Commands::Bind.new(
          streams,
          middleman_runner: runner,
          output_locations: output_locations,
          config_fetcher: configuration_fetcher(Config::Configuration),
          config_decorator: Config::ConfigurationDecorator.new(loader: config_loader, config_filename: 'bookbinder.yml'),
          file_system_accessor: local_filesystem_accessor,
          link_checker: Postprocessing::LinkChecker.new(local_filesystem_accessor, final_app_directory, streams),
          preprocessor: Preprocessing::Preprocessor.new(
            Preprocessing::DitaHTMLPreprocessor.new(
              local_filesystem_accessor,
              subnav_generator_factory,
              DitaHtmlForMiddlemanFormatter.new(local_filesystem_accessor, html_document_manipulator),
              dita_command_creator,
              sheller
            ),
            Preprocessing::LinkToSiteGenDir.new(local_filesystem_accessor, subnav_generator_factory)
          ),
          cloner_factory: Ingest::ClonerFactory.new(streams, local_filesystem_accessor, version_control_system),
          section_repository: Ingest::SectionRepository.new,
          directory_preparer: directory_preparer
        ).run(*args)
      end

      def watch(repos=[])
        @watch ||= Commands::Watch.new(
          streams,
          middleman_runner: runner,
          output_locations: output_locations,
          config_fetcher: configuration_fetcher(Config::Configuration),
          config_decorator: Config::ConfigurationDecorator.new(loader: config_loader, config_filename: 'bookbinder.yml'),
          file_system_accessor: local_filesystem_accessor,
          preprocessor: Preprocessing::Preprocessor.new(Preprocessing::LinkToSiteGenDir.new(local_filesystem_accessor, subnav_generator_factory)),
          cloner: local_file_system_cloner,
          section_repository: Ingest::SectionRepository.new,
          directory_preparer: directory_preparer,
          repo_restrictions: repos
        ).run
      end

      def imprint(*args)
        Bookbinder::Commands::Imprint.new(
          streams,
          output_locations: output_locations,
          config_fetcher: configuration_fetcher(Config::Imprint::Configuration),
          preprocessor: Preprocessing::Preprocessor.new(Preprocessing::DitaPDFPreprocessor.new(local_filesystem_accessor, dita_command_creator, sheller)),
          cloner_factory: Ingest::ClonerFactory.new(streams, local_filesystem_accessor, version_control_system),
          section_repository: Ingest::SectionRepository.new,
          directory_preparer: Commands::Components::Imprint::DirectoryPreparer.new(local_filesystem_accessor)
        ).run(*args)
      end

      private

      attr_reader :streams, :version_control_system

      def dita_command_creator
        DitaCommandCreator.new(ENV['PATH_TO_DITA_OT_LIBRARY'])
      end

      def configuration_fetcher(config_class)
        Bookbinder::Config::Fetcher.new(
          Bookbinder::Config::Validator.new(local_filesystem_accessor),
          config_loader,
          config_class
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

      def directory_preparer
        Commands::Components::Bind::DirectoryPreparer.new(local_filesystem_accessor)
      end

      def output_locations
        OutputLocations.new(final_app_dir: final_app_directory, context_dir: File.absolute_path('.'))
      end

      def final_app_directory
        @final_app_directory ||= File.absolute_path('final_app')
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
