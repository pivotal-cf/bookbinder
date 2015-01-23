require_relative '../book'
require_relative '../caching_git_accessor'
require_relative '../cli_error'
require_relative '../configuration'
require_relative '../directory_helpers'
require_relative '../middleman_runner'
require_relative '../publisher'
require_relative '../section'
require_relative '../spider'
require_relative 'bookbinder_command'
require_relative 'naming'

module Bookbinder
  module Commands
    class Publish < BookbinderCommand
      VersionUnsupportedError = Class.new(StandardError)

      include Bookbinder::DirectoryHelperMethods
      extend Commands::Naming

      def self.usage
        "publish <local|github> [--verbose] \t Bind the sections specified in config.yml from <local> or <github> into the final_app directory"
      end

      def run(cli_arguments, git_accessor=CachingGitAccessor.new)
        final_app_dir = File.absolute_path('final_app')

        raise CliError::InvalidArguments unless arguments_are_valid?(cli_arguments)
        @git_accessor = git_accessor
        @section_repository = Repositories::SectionRepository.new(
            @logger,
            store: Repositories::SectionRepository::SHARED_CACHE
        )
        @gem_root = File.expand_path('../../../../', __FILE__)
        spider = Spider.new(@logger, app_dir: final_app_dir)
        middleman_runner = MiddlemanRunner.new(@logger, git_accessor)
        server_director = ServerDirector.new(@logger, directory: final_app_dir)

        @publisher = Publisher.new(@logger, spider, middleman_runner, server_director)

        verbosity = cli_arguments.include?('--verbose')
        location = cli_arguments[0]

        cli_options = {verbose: verbosity, target_tag: nil}
        output_paths = output_directory_paths(location, final_app_dir)
        publish_config = publish_config(location)
        @versions = publish_config.fetch(:versions, [])
        @book_repo = publish_config[:book_repo]

        master_middleman_dir = output_paths.fetch(:master_middleman_dir)
        intermediate_directory = output_paths.fetch(:output_dir)
        master_dir = File.join intermediate_directory, 'master_middleman'
        workspace_dir = File.join master_dir, 'source'
        prepare_directories(final_app_dir,
                            intermediate_directory,
                            workspace_dir,
                            master_middleman_dir,
                            master_dir,
                            @git_accessor)

        target_tag = cli_options[:target_tag]
        sections = gather_sections(workspace_dir, publish_config, output_paths, target_tag, @git_accessor)

        subnavs = subnavs_by_dir_name(sections)

        success = publisher.publish(subnavs, cli_options, output_paths, publish_config)

        success ? 0 : 1
      end

      private

      attr_reader :publisher

      def gather_sections(workspace, publish_config, output_paths, target_tag, git_accessor)
        publish_config.fetch(:sections).map do |attributes|

          local_repo_dir = output_paths[:local_repo_dir]
          vcs_repo =
              if local_repo_dir
                GitHubRepository.
                    build_from_local(@logger, attributes, local_repo_dir, git_accessor).
                    tap { |repo| repo.copy_from_local(workspace) }
              else
                GitHubRepository.
                    build_from_remote(@logger, attributes, target_tag, git_accessor).
                    tap { |repo| repo.copy_from_remote(workspace) }
              end

          @section_repository.get_instance(attributes,
                                          vcs_repo: vcs_repo,
                                          destination_dir: workspace,
                                          build: ->(*args) { Section.new(*args) })
        end
      end

      def prepare_directories(final_app, middleman_scratch_space, middleman_source, master_middleman_dir, middleman_dir, git_accessor)
        forget_sections(middleman_scratch_space)
        FileUtils.rm_rf File.join final_app, '.'
        FileUtils.mkdir_p middleman_scratch_space
        FileUtils.mkdir_p File.join final_app, 'public'
        FileUtils.mkdir_p middleman_source

        copy_directory_from_gem 'template_app', final_app
        copy_directory_from_gem 'master_middleman', middleman_dir
        FileUtils.cp_r File.join(master_middleman_dir, '.'), middleman_dir

        copy_version_master_middleman(middleman_source, git_accessor)
      end

      def forget_sections(middleman_scratch)
        Repositories::SectionRepository::SHARED_CACHE.clear
        FileUtils.rm_rf File.join middleman_scratch, '.'
      end

      def copy_directory_from_gem(dir, output_dir)
        FileUtils.cp_r File.join(@gem_root, "#{dir}/."), output_dir
      end

      # Copy the index file from each version into the version's directory. Because version
      # subdirectories are sections, this is the only way they get content from their master
      # middleman directory.
      def copy_version_master_middleman(dest_dir, git_accessor)
        @versions.each do |version|
          Dir.mktmpdir(version) do |tmpdir|
            book = Book.from_remote(logger: @logger,
                                    full_name: @book_repo,
                                    destination_dir: tmpdir,
                                    ref: version,
                                    git_accessor: git_accessor)
            index_source_dir = File.join(tmpdir, book.directory, 'master_middleman', source_dir_name)
            index_dest_dir = File.join(dest_dir, version)
            FileUtils.mkdir_p(index_dest_dir)

            Dir.glob(File.join(index_source_dir, 'index.*')) do |f|
              FileUtils.cp(File.expand_path(f), index_dest_dir)
            end
          end
        end
      end

      def output_directory_paths(location, final_app_dir)
        local_repo_dir = (location == 'local') ? File.absolute_path('..') : nil

        {
          final_app_dir: final_app_dir,
          local_repo_dir: local_repo_dir,
          output_dir: File.absolute_path(output_dir_name),
          master_middleman_dir: layout_repo_path(local_repo_dir)
        }
      end

      def publish_config(location)
        arguments = {
            sections: config.sections,
            book_repo: config.book_repo,
            host_for_sitemap: config.public_host,
            archive_menu: config.archive_menu
        }

        optional_arguments = {}
        optional_arguments.merge!(template_variables: config.template_variables) if config.respond_to?(:template_variables)
        if publishing_to_github? location
          config.versions.each { |version| arguments[:sections].concat sections_from version, @git_accessor }
          optional_arguments.merge!(versions: config.versions)
        end

        arguments.merge! optional_arguments
      end

      def sections_from(version, git_accessor)
        config_file = File.join book_checkout(version, git_accessor), 'config.yml'
        attrs       = YAML.load(File.read(config_file))['sections']
        raise VersionUnsupportedError.new(version) if attrs.nil?

        attrs.map do |section_hash|
          section_hash['repository']['ref'] = version
          section_hash['directory'] = File.join(version, section_hash['directory'])
          section_hash
        end
      end

      def book_checkout(ref, git_accessor=Git)
        temp_workspace = Dir.mktmpdir('book_checkout')
        book = Book.from_remote(logger: @logger,
                                full_name: config.book_repo,
                                destination_dir: temp_workspace,
                                ref: ref,
                                git_accessor: git_accessor,
                               )

        File.join temp_workspace, book.directory
      end

      def layout_repo_path(local_repo_dir)
        if config.has_option?('layout_repo')
          if local_repo_dir
            File.join(local_repo_dir, config.layout_repo.split('/').last)
          else
            section = {'repository' => {'name' => config.layout_repo}}
            destination_dir = Dir.mktmpdir
            repository = GitHubRepository.build_from_remote(@logger,
                                                            section,
                                                            'master',
                                                            @git_accessor)
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

      def publishing_to_github?(publish_location)
        config.has_option?('versions') && publish_location != 'local'
      end

      def subnavs_by_dir_name(sections)
        sections.reduce({}) do |subnavs, section|
          namespace = section.directory.gsub('/', '_')
          template = section.subnav_template || 'default'

          subnavs.merge(namespace => template)
        end
      end
    end
  end
end
