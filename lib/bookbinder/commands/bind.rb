require 'middleman-syntax'

require_relative '../errors/cli_error'
require_relative 'bind/bind_options'
require_relative 'naming'

module Bookbinder
  module Commands
    class Bind
      include Commands::Naming

      def initialize(base_streams,
                     output_locations,
                     config_fetcher,
                     config_decorator,
                     file_system_accessor,
                     static_site_generator,
                     sitemap_writer,
                     preprocessor,
                     cloner_factory,
                     section_repository,
                     directory_preparer)
        @base_streams = base_streams
        @output_locations = output_locations
        @config_fetcher = config_fetcher
        @config_decorator = config_decorator
        @file_system_accessor = file_system_accessor
        @static_site_generator = static_site_generator
        @sitemap_writer = sitemap_writer
        @preprocessor = preprocessor
        @cloner_factory = cloner_factory
        @section_repository = section_repository
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
        bind_options        = BindComponents::BindOptions.new(cli_arguments, base_streams).tap(&:validate!)
        bind_config         = config_fetcher.fetch_config
        cloner              = cloner_factory.produce(bind_options.local_repo_dir)

        directory_preparer.prepare_directories(
          File.expand_path('../../../../', __FILE__),
          output_locations,
          layout_repo_path(bind_config, cloner)
        )
        sections = section_repository.fetch(
          configured_sections: bind_config.sections,
          destination_dir: output_locations.cloned_preprocessing_dir,
          ref_override: bind_options.ref_override,
          cloner: cloner,
          streams: bind_options.streams
        )
        preprocessor.preprocess(
          sections,
          output_locations,
          options: bind_options.options,
          output_streams: bind_options.streams
        )
        if file_system_accessor.file_exist?('redirects.rb')
          file_system_accessor.copy('redirects.rb', output_locations.final_app_dir)
        end
        generation_result = static_site_generator.run(
          "build #{bind_options.verbosity}",
          streams: bind_options.streams,
          output_locations: output_locations,
          config: config_decorator.generate(bind_config, sections),
          local_repo_dir: bind_options.local_repo_dir,
          subnavs: subnavs(sections)
        )
        if generation_result.success?
          file_system_accessor.copy(output_locations.build_dir, output_locations.public_dir)
          result = sitemap_writer.write(
            bind_config.public_host,
            bind_options.streams,
            bind_config.broken_link_exclusions
          )

          bind_options.streams[:success].puts "Bookbinder bound your book into #{output_locations.final_app_dir}"

          result.has_broken_links? ? 1 : 0
        else
          1
        end
      end

      private

      attr_reader(
        :base_streams,
        :cloner_factory,
        :config_decorator,
        :config_fetcher,
        :directory_preparer,
        :file_system_accessor,
        :final_app_directory,
        :output_locations,
        :preprocessor,
        :section_repository,
        :sitemap_writer,
        :static_site_generator,
      )

      def subnavs(sections)
        sections.map(&:subnav).reduce({}, :merge)
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
