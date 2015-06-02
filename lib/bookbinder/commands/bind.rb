require 'middleman-syntax'

require_relative '../config/archive_menu_configuration'
require_relative '../errors/cli_error'
require_relative '../values/output_locations'
require_relative '../values/section'
require_relative 'bind/bind_options'
require_relative 'naming'

module Bookbinder
  module Commands
    class Bind
      include Commands::Naming

      def initialize(logger,
                     config_factory,
                     archive_menu_config,
                     version_control_system,
                     file_system_accessor,
                     static_site_generator,
                     sitemap_writer,
                     final_app_directory,
                     context_dir,
                     preprocessor,
                     cloner_factory,
                     section_repository_factory,
                     directory_preparer)
        @logger = logger
        @config_factory = config_factory
        @archive_menu_config = archive_menu_config
        @version_control_system = version_control_system
        @file_system_accessor = file_system_accessor
        @static_site_generator = static_site_generator
        @sitemap_writer = sitemap_writer
        @final_app_directory = final_app_directory
        @context_dir = context_dir
        @preprocessor = preprocessor
        @cloner_factory = cloner_factory
        @section_repository_factory = section_repository_factory
        @directory_preparer = directory_preparer
      end

      def usage
        ["bind <local|remote> [--verbose] [--dita-flags='<dita-option>=<value>']",
         "Bind the sections specified in config.yml from <local> or <remote> into the final_app directory"]
      end

      def command_for?(test_command_name)
        %w(bind publish).include?(test_command_name)
      end

      def deprecated_command_for?(command_name)
        %w(publish).include?(command_name)
      end

      def run(cli_arguments)
        bind_options = BindComponents::BindOptions.new(cli_arguments)
        bind_options.validate!

        bind_source, *options = cli_arguments
        bind_config = config_factory.produce(bind_source)

        local_repo_dir = generate_local_repo_dir(context_dir, bind_source)
        cloner = cloner_factory.produce(local_repo_dir)
        output_locations = OutputLocations.new(
          context_dir: context_dir,
          final_app_dir: final_app_directory,
          layout_repo_dir: layout_repo_path(bind_config, cloner),
        )
        section_repository = section_repository_factory.produce(cloner)

        directory_preparer.prepare_directories(
          bind_config,
          File.expand_path('../../../../', __FILE__),
          output_locations
        )

        sections = section_repository.fetch(
          configured_sections: bind_config.sections,
          destination_dir: output_locations.cloned_preprocessing_dir,
          ref_override: bind_options.ref_override
        )

        preprocessor.preprocess(sections,
                                output_locations,
                                options: options,
                                output_streams: bind_options.streams)

        success = publish(
          sections.map(&:subnav).reduce({}, :merge),
          {verbose: options.include?('--verbose')},
          output_locations,
          archive_menu_config.generate(bind_config, sections),
          cloner
        )

        success ? 0 : 1
      end

      private

      attr_reader :version_control_system,
                  :config_factory,
                  :archive_menu_config,
                  :logger,
                  :file_system_accessor,
                  :static_site_generator,
                  :final_app_directory,
                  :sitemap_writer,
                  :context_dir,
                  :preprocessor,
                  :cloner_factory,
                  :section_repository_factory,
                  :directory_preparer

      def publish(subnavs, cli_options, output_locations, publish_config, cloner)
        FileUtils.cp 'redirects.rb', output_locations.final_app_dir if File.exists?('redirects.rb')

        host_for_sitemap = publish_config.public_host

        static_site_generator.run(output_locations,
                                  publish_config,
                                  cloner,
                                  cli_options[:verbose],
                                  subnavs)
        file_system_accessor.copy output_locations.build_dir, output_locations.public_dir


        result = generate_sitemap(host_for_sitemap)

        logger.log "Bookbinder bound your book into #{output_locations.final_app_dir.to_s.green}"

        !result.has_broken_links?
      end

      def generate_sitemap(host_for_sitemap)
        raise "Your public host must be a single String." unless host_for_sitemap.is_a?(String)
        sitemap_writer.write(host_for_sitemap)
      end

      def generate_local_repo_dir(context_dir, bind_source)
        File.expand_path('..', context_dir) if bind_source == 'local'
      end

      def layout_repo_path(config, cloner)
        if config.has_option?('layout_repo')
          working_copy = cloner.call(source_repo_name: config.layout_repo,
                                     destination_parent_dir: Dir.mktmpdir)
          working_copy.path
        else
          File.absolute_path('master_middleman')
        end
      end
    end
  end
end
