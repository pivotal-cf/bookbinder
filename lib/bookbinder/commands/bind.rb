require 'middleman-syntax'

require_relative 'components/command_options'
require_relative 'naming'

module Bookbinder
  module Commands
    class Bind
      def initialize(base_streams,
                     output_locations: nil,
                     config_fetcher: nil,
                     config_decorator: nil,
                     file_system_accessor: nil,
                     middleman_runner: nil,
                     broken_links_checker: nil,
                     preprocessor: nil,
                     cloner_factory: nil,
                     section_repository: nil,
                     directory_preparer: nil)

        @base_streams = base_streams
        @output_locations = output_locations
        @config_fetcher = config_fetcher
        @config_decorator = config_decorator
        @file_system_accessor = file_system_accessor
        @middleman_runner = middleman_runner
        @broken_links_checker = broken_links_checker
        @preprocessor = preprocessor
        @cloner_factory = cloner_factory
        @section_repository = section_repository
        @directory_preparer = directory_preparer
      end

      def usage
        ["bind <local|remote> [--verbose] [--dita-flags=\\\"<dita-option>=<value>\\\"]",
         "Bind the sections specified in config.yml from <local> or <remote> into the final_app directory"]
      end

      def command_for?(test_command_name)
        'bind' == test_command_name
      end

      def run(cli_arguments)
        bind_options        = Components::CommandOptions.new(cli_arguments, base_streams).tap(&:validate!)
        bind_config         = config_fetcher.fetch_config
        cloner              = cloner_factory.produce(bind_options.local_repo_dir)

        directory_preparer.prepare_directories(
          bind_config,
          File.expand_path('../../../../', __FILE__),
          output_locations,
          cloner,
          ref_override: bind_options.ref_override
        )

        sections = section_repository.fetch(
          configured_sections: bind_config.sections,
          destination_dir: output_locations.cloned_preprocessing_dir,
          ref_override: bind_options.ref_override,
          cloner: cloner,
          streams: base_streams
        )
        preprocessor.preprocess(
          sections,
          output_locations,
          options: bind_options.options,
          output_streams: bind_options.streams,
          config: bind_config
        )
        if file_system_accessor.file_exist?('redirects.rb')
          file_system_accessor.copy('redirects.rb', output_locations.final_app_dir)
        end

        generation_result = middleman_runner.run(
          'build --verbose',
          streams: bind_options.streams,
          output_locations: output_locations,
          config: config_decorator.generate(bind_config, sections),
          local_repo_dir: bind_options.local_repo_dir,
          subnavs: subnavs(sections),
          product_info: product_infos(sections)
        )
        if generation_result.success?
          file_system_accessor.copy(output_locations.build_dir, output_locations.public_dir)

          broken_links_checker.check!(bind_config.broken_link_exclusions)
          broken_links_checker.announce(bind_options.streams)

          bind_options.streams[:success].puts "Bookbinder bound your book into #{output_locations.final_app_dir}"

          broken_links_checker.has_broken_links? ? 1 : 0
        else
          bind_options.streams[:err].puts "Your bind failed. Rerun with --verbose to troubleshoot."
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
        :broken_links_checker,
        :middleman_runner,
      )

      def subnavs(sections)
        sections.map(&:subnav).reduce({}, :merge)
      end

      def product_infos(sections)
        temp = Hash.new
        sections.each do |section|
          temp[section.namespace] = section.product_info
        end
        temp
      end
    end
  end
end
