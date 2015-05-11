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
    class Bind
      include Commands::Naming

      DitaToHtmlLibraryFailure = Class.new(RuntimeError)

      def initialize(logger,
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
        ["bind <local|github> [--verbose] [--dita-flags='<dita-option>=<value>']",
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
          layout_repo_dir: layout_repo_path(bind_config, generate_local_repo_dir(context_dir, bind_source)),
          local_repo_dir: generate_local_repo_dir(context_dir, bind_source)
        )

        directory_preparer.prepare_directories(
          bind_config,
          File.expand_path('../../../../', __FILE__),
          output_locations
        )

        dita_gatherer = dita_section_gatherer_factory.produce(bind_source, output_locations)
        gathered_dita_sections = dita_gatherer.gather(bind_config.dita_sections)

        dita_preprocessor.preprocess(gathered_dita_sections,
                                     output_locations.subnavs_for_layout_dir,
                                     output_locations.dita_subnav_template_path) do |dita_section|
          command = command_creator.convert_to_html_command(
            dita_section,
            dita_flags: dita_flags(options),
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
          bind_config,
          output_locations.source_for_site_generator,
          cloner,
          ('master' if options.include?('--ignore-section-refs'))
        )

        subnavs = (sections + gathered_dita_sections).map(&:subnav).reduce(&:merge)

        success = publish(
          subnavs,
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
                  :dita_preprocessor,
                  :cloner_factory,
                  :dita_section_gatherer_factory,
                  :section_repository,
                  :command_creator,
                  :sheller,
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

      def gather_sections(config, workspace, cloner, ref_override)
        config.sections.map do |section_config|
          target_ref = ref_override ||
            section_config.fetch('repository', {})['ref'] ||
            'master'
          repo_name = section_config.fetch('repository').fetch('name')
          directory = section_config['directory']
          working_copy = cloner.call(source_repo_name: repo_name,
                                     source_ref: target_ref,
                                     destination_parent_dir: workspace,
                                     destination_dir_name: directory)
          @section_repository.get_instance(
            section_config,
            working_copy: working_copy,
            destination_dir: workspace
          ) { |*args| Section.new(*args) }
        end
      end

      def layout_repo_path(config, local_repo_dir)
        if local_repo_dir && config.has_option?('layout_repo')
          File.join(local_repo_dir, config.layout_repo.split('/').last)
        elsif config.has_option?('layout_repo')
          cloner = cloner_factory.produce('github', nil)
          working_copy = cloner.call(source_repo_name: config.layout_repo,
                                     destination_parent_dir: Dir.mktmpdir)
          working_copy.path
        else
          File.absolute_path('master_middleman')
        end
      end

      def validate(bind_source, options)
        raise CliError::InvalidArguments unless arguments_are_valid?(bind_source, options)
      end

      def arguments_are_valid?(bind_source, options)
        valid_options = %w(--verbose --ignore-section-refs --dita-flags).to_set
        %w(local github).include?(bind_source) && flag_names(options).to_set.subset?(valid_options)
      end

      def flag_names(opts)
        opts.map {|o| o.split('=').first}
      end

      def dita_flags(opts)
        matching_flags = opts.map {|o| o[flag_value_regex("dita-flags"), 1] }
        matching_flags.compact.first
      end

      def flag_value_regex(flag_name)
        Regexp.new(/--#{flag_name}=(.+)/)
      end
    end
  end
end
