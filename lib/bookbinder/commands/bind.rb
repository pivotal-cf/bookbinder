require 'middleman-syntax'

require_relative '../config/archive_menu_configuration'
require_relative '../errors/cli_error'
require_relative 'bind/bind_options'
require_relative 'naming'

module Bookbinder
  module Commands
    class Bind
      include Commands::Naming

      def initialize(base_streams,
                     output_locations,
                     config_factory,
                     archive_menu_config,
                     file_system_accessor,
                     static_site_generator,
                     sitemap_writer,
                     preprocessor,
                     cloner_factory,
                     section_repository_factory,
                     directory_preparer)
        @base_streams = base_streams
        @output_locations = output_locations
        @config_factory = config_factory
        @archive_menu_config = archive_menu_config
        @file_system_accessor = file_system_accessor
        @static_site_generator = static_site_generator
        @sitemap_writer = sitemap_writer
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
        bind_options = BindComponents::BindOptions.new(cli_arguments, base_streams)
        bind_options.validate!

        bind_source, *options = cli_arguments
        bind_config = config_factory.produce(bind_source)

        local_repo_dir = generate_local_repo_dir(context_dir, bind_source)
        cloner = cloner_factory.produce(local_repo_dir)
        section_repository = section_repository_factory.produce(cloner)

        directory_preparer.prepare_directories(
          bind_config,
          File.expand_path('../../../../', __FILE__),
          output_locations,
          layout_repo_path(bind_config, cloner)
        )

        sections = section_repository.fetch(
          configured_sections: bind_config.sections,
          destination_dir: output_locations.cloned_preprocessing_dir,
          ref_override: bind_options.ref_override
        )

        preprocessor.preprocess(
          sections,
          output_locations,
          options: options,
          output_streams: bind_options.streams
        )

        success = publish(
          sections.map(&:subnav).reduce({}, :merge),
          {verbose: options.include?('--verbose')},
          bind_options.streams,
          output_locations,
          archive_menu_config.generate(bind_config, sections),
          cloner
        )

        success ? 0 : 1
      end

      private

      attr_reader(
        :archive_menu_config,
        :base_streams,
        :cloner_factory,
        :config_factory,
        :context_dir,
        :directory_preparer,
        :file_system_accessor,
        :final_app_directory,
        :output_locations,
        :preprocessor,
        :section_repository_factory,
        :sitemap_writer,
        :static_site_generator,
      )

      def publish(subnavs, cli_options, streams, output_locations, publish_config, cloner)
        FileUtils.cp 'redirects.rb', output_locations.final_app_dir if File.exists?('redirects.rb')

        host_for_sitemap = publish_config.public_host

        static_site_generator.run(output_locations,
                                  publish_config,
                                  cloner,
                                  cli_options[:verbose],
                                  subnavs)
        file_system_accessor.copy output_locations.build_dir, output_locations.public_dir

        raise "Your public host must be a single String." unless host_for_sitemap.is_a?(String)
        result = sitemap_writer.write(
          host_for_sitemap,
          streams,
          publish_config.broken_link_exclusions
        )

        streams[:success].puts "Bookbinder bound your book into #{output_locations.final_app_dir}"

        !result.has_broken_links?
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
