require 'middleman-syntax'

require_relative '../archive_menu_configuration'
require_relative '../book'
require_relative '../dita_section_gatherer_factory'
require_relative '../errors/cli_error'
require_relative '../streams/switchable_stdout_and_red_stderr'
require_relative '../values/dita_section'
require_relative '../values/output_locations'
require_relative '../values/section'
require_relative 'naming'

module Bookbinder
  module Commands
    class BindValidator
      MissingRequiredKeyError = Class.new(RuntimeError)
    end

    class Bind
      include Commands::Naming

      DitaToHtmlLibraryFailure = Class.new(RuntimeError)

      def initialize(logger,
                     config_fetcher,
                     config_factory,
                     archive_menu_config,
                     version_control_system,
                     file_system_accessor,
                     static_site_generator,
                     sitemap_writer,
                     final_app_directory,
                     context_dir,
                     dita_preprocessor,
                     cloner_factory,
                     dita_section_gatherer_factory,
                     section_repository,
                     command_creator,
                     sheller,
                     directory_preparer)
        @logger = logger
        @config_fetcher = config_fetcher
        @config_factory = config_factory
        @archive_menu_config = archive_menu_config
        @version_control_system = version_control_system
        @file_system_accessor = file_system_accessor
        @static_site_generator = static_site_generator
        @sitemap_writer = sitemap_writer
        @final_app_directory = final_app_directory
        @context_dir = context_dir
        @dita_preprocessor = dita_preprocessor
        @cloner_factory = cloner_factory
        @dita_section_gatherer_factory = dita_section_gatherer_factory
        @section_repository = section_repository
        @command_creator = command_creator
        @sheller = sheller
        @directory_preparer = directory_preparer
      end

      def usage
        ["bind <local|github> [--verbose]",
         "Bind the sections specified in config.yml from <local> or <github> into the final_app directory"]
      end

      def command_for?(test_command_name)
        %w(bind publish).include?(test_command_name)
      end

      def deprecated_command_for?(command_name)
        %w(publish).include?(command_name)
      end

      def run(cli_arguments)
        bind_source, *options = cli_arguments
        validate(bind_source, options)

        bind_config = config_factory.produce(bind_source)
        output_streams = Streams::SwitchableStdoutAndRedStderr.new(options)

        output_locations = OutputLocations.new(
          context_dir: context_dir,
          final_app_dir: final_app_directory,
          layout_repo_dir: layout_repo_path(generate_local_repo_dir(context_dir, bind_source)),
          local_repo_dir: generate_local_repo_dir(context_dir, bind_source)
        )

        directory_preparer.prepare_directories(
          File.expand_path('../../../../', __FILE__),
          bind_config.fetch(:versions, []),
          output_locations,
          bind_config[:book_repo]
        )

        dita_gatherer = dita_section_gatherer_factory.produce(bind_source, output_locations)
        gathered_dita_sections = dita_gatherer.gather(config.dita_sections)

        dita_preprocessor.preprocess(gathered_dita_sections,
                                     output_locations.subnavs_for_layout_dir,
                                     output_locations.dita_subnav_template_path) do |dita_section|
          command = command_creator.convert_to_html_command(
            dita_section,
            write_to: dita_section.html_from_dita_section_dir
          )
          status = sheller.run_command(command, output_streams.to_h)
          unless status.success?
            raise DitaToHtmlLibraryFailure.new 'The DITA-to-HTML conversion failed. ' +
              'Please check that you have specified the path to your DITA-OT library in the ENV, ' +
              'that your DITA-specific keys/values in config.yml are set, ' +
              'and that your DITA toolkit is correctly configured.'
          end
        end

        cloner = cloner_factory.produce(
          bind_source,
          output_locations.local_repo_dir
        )
        sections = gather_sections(
          output_locations.source_for_site_generator,
          cloner,
          ('master' if options.include?('--ignore-section-refs'))
        )

        subnavs = (sections + gathered_dita_sections).map(&:subnav).reduce(&:merge)

        success = publish(
          subnavs,
          {verbose: options.include?('--verbose')},
          output_locations,
          archive_menu_config.generate(bind_config, sections)
        )

        success ? 0 : 1
      end

      private

      attr_reader :version_control_system,
                  :config_fetcher,
                  :config_factory,
                  :archive_menu_config,
                  :logger,
                  :file_system_accessor,
                  :static_site_generator,
                  :final_app_directory,
                  :sitemap_writer,
                  :context_dir,
                  :dita_preprocessor,
                  :cloner_factory,
                  :dita_section_gatherer_factory,
                  :section_repository,
                  :command_creator,
                  :sheller,
                  :directory_preparer

      def publish(subnavs, cli_options, output_paths, publish_config)
        intermediate_directory = output_paths.output_dir
        final_app_dir = output_paths.final_app_dir
        master_dir = File.join intermediate_directory, 'master_middleman'
        workspace_dir = File.join master_dir, 'source'
        build_directory = File.join master_dir, 'build/.'
        public_directory = File.join final_app_dir, 'public'

        FileUtils.cp 'redirects.rb', final_app_dir if File.exists?('redirects.rb')

        host_for_sitemap = publish_config.fetch(:host_for_sitemap)

        generate_site(cli_options, output_paths, publish_config, master_dir, workspace_dir, subnavs, build_directory, public_directory)
        result = generate_sitemap(host_for_sitemap)

        logger.log "Bookbinder bound your book into #{final_app_dir.to_s.green}"

        !result.has_broken_links?
      end

      def generate_sitemap(host_for_sitemap)
        raise "Your public host must be a single String." unless host_for_sitemap.is_a?(String)
        sitemap_writer.write(host_for_sitemap)
      end

      def generate_site(cli_options, output_paths, publish_config, middleman_dir, workspace_dir, subnavs, build_dir, public_dir)
        static_site_generator.run(middleman_dir,
                                  workspace_dir,
                                  publish_config.fetch(:template_variables, {}),
                                  output_paths.local_repo_dir,
                                  cli_options[:verbose],
                                  subnavs,
                                  publish_config[:host_for_sitemap],
                                  publish_config[:archive_menu])
        file_system_accessor.copy build_dir, public_dir
      end

      def generate_local_repo_dir(context_dir, bind_source)
        File.expand_path('..', context_dir) if bind_source == 'local'
      end

      def gather_sections(workspace, cloner, ref_override)
        config.sections.map do |attributes|
          target_ref = ref_override ||
            attributes.fetch('repository', {})['ref'] ||
            'master'
          repo_name = attributes.fetch('repository').fetch('name')
          directory = attributes['directory']
          vcs_repo = cloner.call(from: repo_name,
                                 ref: target_ref,
                                 parent_dir: workspace,
                                 dir_name: directory)
          @section_repository.get_instance(
            attributes,
            vcs_repo: vcs_repo,
            destination_dir: workspace
          ) { |*args| Section.new(*args) }
        end
      end

      def config
        config_fetcher.fetch_config
      end

      def layout_repo_path(local_repo_dir)
        if config.has_option?('layout_repo')
          if local_repo_dir
            File.join(local_repo_dir, config.layout_repo.split('/').last)
          else
            section = {'repository' => {'name' => config.layout_repo}}
            destination_dir = Dir.mktmpdir
            repository = GitHubRepository.build_from_remote(logger,
                                                            section,
                                                            version_control_system)
            repository.copy_from_remote(destination_dir, 'master')
            if repository
              File.join(destination_dir, repository.directory)
            else
              raise 'failed to fetch repository'
            end
          end
        else
          File.absolute_path('master_middleman')
        end
      end

      def validate(bind_source, options)
        raise CliError::InvalidArguments unless arguments_are_valid?(bind_source, options)
      end

      def arguments_are_valid?(bind_source, options)
        valid_options = %w(--verbose --ignore-section-refs).to_set
        %w(local github).include?(bind_source) && options.to_set.subset?(valid_options)
      end
    end
  end
end
