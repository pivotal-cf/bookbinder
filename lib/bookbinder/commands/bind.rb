require_relative '../archive_menu_configuration'
require_relative '../book'
require_relative '../cli_error'
require_relative '../directory_helpers'
require_relative '../publisher'
require_relative '../section'
require_relative '../dita_section'
require_relative '../dita_section_gatherer'
require_relative 'naming'

module Bookbinder
  module Commands
    class Bind
      VersionUnsupportedError = Class.new(RuntimeError)

      include Bookbinder::DirectoryHelperMethods
      include Commands::Naming

      def initialize(logger,
                     config_fetcher,
                     archive_menu_config,
                     version_control_system,
                     file_system_accessor,
                     static_site_generator,
                     sitemap_generator,
                     final_app_directory,
                     server_director,
                     context_dir,
                     dita_preprocessor)
        @logger = logger
        @config_fetcher = config_fetcher
        @archive_menu_config = archive_menu_config
        @version_control_system = version_control_system
        @file_system_accessor = file_system_accessor
        @static_site_generator = static_site_generator
        @sitemap_generator = sitemap_generator
        @final_app_directory = final_app_directory
        @server_director = server_director
        @context_dir = context_dir
        @dita_preprocessor = dita_preprocessor
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
        raise CliError::InvalidArguments unless arguments_are_valid?(cli_arguments)
        @section_repository = Repositories::SectionRepository.new(logger)
        @gem_root = File.expand_path('../../../../', __FILE__)

        @publisher = Publisher.new(logger, sitemap_generator, static_site_generator, server_director, file_system_accessor)

        location = cli_arguments[0]

        output_paths = output_directory_paths(location)
        bind_config = bind_config(location)
        @versions = bind_config.fetch(:versions, [])
        @book_repo = bind_config[:book_repo]

        master_middleman_dir = output_paths.fetch(:master_middleman_dir)
        output_dir = output_paths.fetch(:output_dir)

        master_dir = File.join output_dir, 'master_middleman'
        workspace_dir = File.join master_dir, 'source'

        dita_processing_dir = File.join output_dir, 'dita'
        dita_section_dir = File.join dita_processing_dir, 'dita_sections'
        dita_processed_dir = File.join dita_processing_dir, 'html_from_dita'
        subnavs_dir = File.join workspace_dir, 'subnavs'
        dita_subnav_template_path = File.join workspace_dir, 'subnavs', '_dita_subnav_template.erb'
        formatted_dir = File.join dita_processing_dir, 'site_generator_ready'

        prepare_directories(final_app_directory,
                            output_dir,
                            workspace_dir,
                            master_middleman_dir,
                            master_dir,
                            dita_processing_dir,
                            formatted_dir)

        dita_section_config_hash = config.dita_sections || {}
        dita_sections = dita_section_config_hash.map do |dita_section_config|
          relative_path_to_dita_map = dita_section_config['ditamap_location']
          full_name = dita_section_config.fetch('repository', {}).fetch('name')
          target_ref = dita_section_config.fetch('repository', {})['ref']
          directory = dita_section_config['directory']

          DitaSection.new(nil, relative_path_to_dita_map, full_name, target_ref, directory)
        end

        if location == 'github'
          dita_section_gatherer = DitaSectionGatherer.new(version_control_system, logger)
          gathered_dita_sections = dita_section_gatherer.gather(dita_sections, to: dita_section_dir)
        else
          gathered_dita_sections = dita_sections.map do |dita_section|
            relative_path_to_dita_map = dita_section.ditamap_location
            full_name = dita_section.full_name
            target_ref = dita_section.target_ref
            directory = dita_section.directory

            path_to_local_copy = File.join output_paths[:local_repo_dir], directory

            DitaSection.new(path_to_local_copy, relative_path_to_dita_map, full_name, target_ref, directory)
          end
        end

        dita_preprocessor.preprocess(gathered_dita_sections,
                                     dita_processed_dir,
                                     formatted_dir,
                                     workspace_dir,
                                     subnavs_dir,
                                     dita_subnav_template_path)

        sections = gather_sections(workspace_dir, output_paths)

        subnavs = (sections + gathered_dita_sections).map(&:subnav).reduce(&:merge)

        success = publisher.publish(
          subnavs,
          {verbose: cli_arguments.include?('--verbose')},
          output_paths,
          archive_menu_config.generate(bind_config, sections)
        )

        success ? 0 : 1
      end

      private

      attr_reader :publisher,
                  :version_control_system,
                  :config_fetcher,
                  :archive_menu_config,
                  :logger,
                  :file_system_accessor,
                  :static_site_generator,
                  :final_app_directory,
                  :sitemap_generator,
                  :server_director,
                  :context_dir,
                  :dita_preprocessor

      def gather_sections(workspace, output_paths)
        config.sections.map do |attributes|

          local_repo_dir = output_paths[:local_repo_dir]
          vcs_repo =
              if local_repo_dir
                GitHubRepository.
                    build_from_local(logger, attributes, local_repo_dir, version_control_system).
                    tap { |repo| repo.copy_from_local(workspace) }
              else
                GitHubRepository.
                    build_from_remote(logger, attributes, nil, version_control_system).
                    tap { |repo| repo.copy_from_remote(workspace) }
              end

          @section_repository.get_instance(attributes,
                                           vcs_repo: vcs_repo,
                                           destination_dir: workspace,
                                           build: ->(*args) { Section.new(*args) })
        end
      end

      def prepare_directories(final_app,
                              output_dir,
                              middleman_source,
                              master_middleman_dir,
                              middleman_dir,
                              dita_processing_dir,
                              formatted_dir)
        forget_sections(output_dir)
        file_system_accessor.remove_directory File.join final_app, '.'
        file_system_accessor.remove_directory dita_processing_dir
        file_system_accessor.make_directory output_dir
        file_system_accessor.make_directory formatted_dir
        file_system_accessor.make_directory File.join dita_processing_dir, 'dita_sections'
        file_system_accessor.make_directory File.join final_app, 'public'
        file_system_accessor.make_directory middleman_source

        copy_directory_from_gem 'template_app', final_app
        copy_directory_from_gem 'master_middleman', middleman_dir
        file_system_accessor.copy File.join(master_middleman_dir, '.'), middleman_dir

        copy_version_master_middleman(middleman_source)
      end

      def forget_sections(middleman_scratch)
        file_system_accessor.remove_directory File.join middleman_scratch, '.'
      end

      def copy_directory_from_gem(dir, output_dir)
        file_system_accessor.copy File.join(@gem_root, "#{dir}/."), output_dir
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

      def output_directory_paths(location)
        local_repo_dir = (location == 'local') ? File.expand_path('..', context_dir) : nil

        {
          final_app_dir: final_app_directory,
          local_repo_dir: local_repo_dir,
          output_dir: File.join(context_dir, output_dir_name),
          master_middleman_dir: layout_repo_path(local_repo_dir)
        }
      end

      def bind_config(location)
        arguments = {
            sections: config.sections,
            book_repo: config.book_repo,
            host_for_sitemap: config.public_host,
            archive_menu: config.archive_menu
        }

        optional_arguments = {}
        optional_arguments.merge!(template_variables: config.template_variables) if config.respond_to?(:template_variables)
        if binding_from_github? location
          config.versions.each { |version| arguments[:sections].concat sections_from version }
          optional_arguments.merge!(versions: config.versions)
        end

        arguments.merge! optional_arguments
      end

      def config
        config_fetcher.fetch_config
      end

      def sections_from(version)
        Dir.mktmpdir('book_checkout') do |temp_workspace|
          book = Book.from_remote(logger: logger,
                                  full_name: config.book_repo,
                                  destination_dir: temp_workspace,
                                  ref: version,
                                  git_accessor: version_control_system,
          )

          book_checkout_value = File.join temp_workspace, book.directory
          config_file = File.join book_checkout_value, 'config.yml'
          attrs = YAML.load(File.read(config_file))['sections']
          raise VersionUnsupportedError.new(version) if attrs.nil?

          attrs.map do |section_hash|
            section_hash['repository']['ref'] = version
            section_hash['directory'] = File.join(version, section_hash['directory'])
            section_hash
          end
        end
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
                                                            'master',
                                                            version_control_system)
            repository.copy_from_remote(destination_dir)
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

      def arguments_are_valid?(arguments)
        return false unless arguments.any?
        verbose           = arguments[1] && arguments[1..-1].include?('--verbose')
        tag_provided      = arguments[1] && (arguments[1..-1] - ['--verbose']).any?
        nothing_special   = arguments[1..-1].empty?

        %w(local github).include?(arguments[0]) && (tag_provided || verbose || nothing_special)
      end

      def binding_from_github?(bind_location)
        config.has_option?('versions') && bind_location != 'local'
      end
    end
  end
end
