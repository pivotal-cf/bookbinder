require_relative '../dita_section_gatherer_factory'
require_relative '../archive_menu_configuration'
require_relative '../values/output_locations'
require_relative '../values/dita_section'
require_relative '../errors/cli_error'
require_relative '../values/section'
require_relative '../publisher'
require_relative '../book'
require_relative 'naming'

module Bookbinder
  module Commands
    class BindValidator
      MissingRequiredKeyError = Class.new(RuntimeError)
    end

    class Bind
      include Bookbinder::DirectoryHelperMethods
      include Commands::Naming

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
                     dita_section_gatherer_factory)
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

        @section_repository = Repositories::SectionRepository.new(logger)
        @gem_root = File.expand_path('../../../../', __FILE__)
        publisher = Publisher.new(logger, sitemap_writer, static_site_generator, file_system_accessor)


        bind_config = config_factory.produce(bind_source)

        @versions = bind_config.fetch(:versions, [])
        @book_repo = bind_config[:book_repo]

        output_locations = OutputLocations.new(
          context_dir: context_dir,
          final_app_dir: final_app_directory,
          layout_repo_dir: layout_repo_path(generate_local_repo_dir(context_dir, bind_source)),
          local_repo_dir: generate_local_repo_dir(context_dir, bind_source)
        )

        prepare_directories(output_locations)

        dita_gatherer = dita_section_gatherer_factory.produce(bind_source, output_locations)
        gathered_dita_sections = dita_gatherer.gather(config.dita_sections)

        gathered_dita_sections.each do |dita_section|
          dita_preprocessor.preprocess(dita_section,
                                       output_locations.subnavs_for_layout_dir,
                                       output_locations.dita_subnav_template_path)
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

        success = publisher.publish(
          subnavs,
          {verbose: cli_arguments.include?('--verbose')},
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
                  :dita_section_gatherer_factory

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

      def prepare_directories(locations)
        forget_sections(locations.output_dir)
        file_system_accessor.remove_directory(File.join(locations.final_app_dir, '.'))
        file_system_accessor.remove_directory(locations.dita_home_dir)

        copy_directory_from_gem('template_app', locations.final_app_dir)
        copy_directory_from_gem('master_middleman', locations.site_generator_home)
        file_system_accessor.copy(File.join(locations.layout_repo_dir, '.'), locations.site_generator_home)

        copy_version_master_middleman(locations.source_for_site_generator)
      end

      # Copy the index file from each version into the version's directory. Because version
      # subdirectories are sections, this is the only way they get content from their master
      # middleman directory.
      def copy_version_master_middleman(dest_dir)
        @versions.each do |version|
          Dir.mktmpdir(version) do |tmpdir|
            book = Book.from_remote(logger: logger,
                                    full_name: @book_repo,
                                    destination_dir: tmpdir,
                                    ref: version,
                                    git_accessor: version_control_system)
            index_source_dir = File.join(tmpdir, book.directory, 'master_middleman', source_dir_name)
            index_dest_dir = File.join(dest_dir, version)
            file_system_accessor.make_directory(index_dest_dir)

            Dir.glob(File.join(index_source_dir, 'index.*')) do |f|
              file_system_accessor.copy(File.expand_path(f), index_dest_dir)
            end
          end
        end
      end

      def forget_sections(middleman_scratch)
        file_system_accessor.remove_directory File.join middleman_scratch, '.'
      end

      def copy_directory_from_gem(dir, output_dir)
        file_system_accessor.copy File.join(@gem_root, "#{dir}/."), output_dir
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

      def binding_from_github?(bind_location)
        config.has_option?('versions') && bind_location != 'local'
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
