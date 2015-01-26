require_relative '../book'
require_relative '../cli_error'
require_relative '../directory_helpers'
require_relative '../middleman_runner'
require_relative '../publisher'
require_relative '../section'
require_relative '../spider'
require_relative 'naming'
require_relative '../dita_section_gatherer'
require_relative '../sheller'
require_relative '../local_file_system_accessor'
require_relative '../local_dita_processor'

module Bookbinder
  module Commands
    class Publish
      VersionUnsupportedError = Class.new(StandardError)

      include Bookbinder::DirectoryHelperMethods
      extend Commands::Naming

      def self.usage
        "publish <local|github> [--verbose] \t Bind the sections specified in config.yml from <local> or <github> into the final_app directory"
      end

      def initialize(logger, config,  version_control_system)
        @logger = logger
        @config = config
        @version_control_system = version_control_system
      end

      def run(cli_arguments)
        final_app_dir = File.absolute_path('final_app')

        raise CliError::InvalidArguments unless arguments_are_valid?(cli_arguments)
        @section_repository = Repositories::SectionRepository.new(
            logger,
            store: Repositories::SectionRepository::SHARED_CACHE
        )
        @gem_root = File.expand_path('../../../../', __FILE__)
        spider = Spider.new(logger, app_dir: final_app_dir)
        middleman_runner = MiddlemanRunner.new(logger, version_control_system)
        server_director = ServerDirector.new(logger, directory: final_app_dir)

        @publisher = Publisher.new(logger, spider, middleman_runner, server_director)

        verbosity = cli_arguments.include?('--verbose')
        location = cli_arguments[0]

        cli_options = {verbose: verbosity, target_tag: nil}
        output_paths = output_directory_paths(location, final_app_dir)
        publish_config = publish_config(location)
        @versions = publish_config.fetch(:versions, [])
        @book_repo = publish_config[:book_repo]

        master_middleman_dir = output_paths.fetch(:master_middleman_dir)
        output_dir = output_paths.fetch(:output_dir)

        tmp_dir = File.join output_dir, 'tmp'
        processed_dita_dir = File.join tmp_dir, 'processed_dita'

        master_dir = File.join output_dir, 'master_middleman'
        workspace_dir = File.join master_dir, 'source'
        prepare_directories(final_app_dir,
                            output_dir,
                            tmp_dir,
                            processed_dita_dir,
                            workspace_dir,
                            master_middleman_dir,
                            master_dir,
                            @version_control_system)

        target_tag = cli_options[:target_tag]

        section_hash = publish_config.fetch(:sections)
        dita_section_config_hash = section_hash.select { |section_attrs| section_attrs.has_key? 'ditamap_location' }
        dita_sections = dita_section_config_hash.map do |dita_section_config|
          relative_path_to_dita_map = dita_section_config['ditamap_location']
          full_name = section_hash.fetch('repository', {}).fetch('name')
          target_ref = section_hash.fetch('repository', {})['ref']
          directory = section_hash['directory']

          DitaSection.new(nil, relative_path_to_dita_map, full_name, target_ref, directory)
        end

        dita_section_gatherer = DitaSectionGatherer.new(version_control_system)
        cloned_dita_sections = dita_section_gatherer.gather(dita_sections, to: tmp_dir)

        file_system_accessor = LocalFileSystemAccessor.new
        location_of_dita_template_file = file_system_accessor.write(
            to: File.join(output_dir, 'transform_dita.xml'),
            text: dita_transform_script(config.path_to_dita_ot_library)
        )

        sheller = Sheller.new
        dita_processor = LocalDitaProcessor.new(sheller, location_of_dita_template_file)

        dita_processor.process(cloned_dita_sections, to:processed_dita_dir)

        sections = gather_sections(workspace_dir, publish_config, output_paths, target_tag, @version_control_system)

        subnavs = subnavs_by_dir_name(sections)

        success = publisher.publish(subnavs, cli_options, output_paths, publish_config)

        success ? 0 : 1
      end

      private

      attr_reader :publisher, :version_control_system, :config, :logger

      def gather_sections(workspace, publish_config, output_paths, target_tag, version_control_system)
        publish_config.fetch(:sections).map do |attributes|

          local_repo_dir = output_paths[:local_repo_dir]
          vcs_repo =
              if local_repo_dir
                GitHubRepository.
                    build_from_local(logger, attributes, local_repo_dir, version_control_system).
                    tap { |repo| repo.copy_from_local(workspace) }
              else
                GitHubRepository.
                    build_from_remote(logger, attributes, target_tag, version_control_system).
                    tap { |repo| repo.copy_from_remote(workspace) }
              end

          @section_repository.get_instance(attributes,
                                          vcs_repo: vcs_repo,
                                          destination_dir: workspace,
                                          build: ->(*args) { Section.new(*args) })
        end
      end

      def prepare_directories(final_app, output_dir, tmp_dir, processed_dita_dir, middleman_source, master_middleman_dir, middleman_dir, version_control_system)
        forget_sections(output_dir)
        FileUtils.rm_rf File.join final_app, '.'
        FileUtils.rm_rf File.join tmp_dir, '.'
        FileUtils.mkdir_p output_dir
        FileUtils.mkdir_p tmp_dir
        FileUtils.mkdir_p processed_dita_dir
        FileUtils.mkdir_p File.join final_app, 'public'
        FileUtils.mkdir_p middleman_source

        copy_directory_from_gem 'template_app', final_app
        copy_directory_from_gem 'master_middleman', middleman_dir
        FileUtils.cp_r File.join(master_middleman_dir, '.'), middleman_dir

        copy_version_master_middleman(middleman_source, version_control_system)
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
      def copy_version_master_middleman(dest_dir, version_control_system)
        @versions.each do |version|
          Dir.mktmpdir(version) do |tmpdir|
            book = Book.from_remote(logger: logger,
                                    full_name: @book_repo,
                                    destination_dir: tmpdir,
                                    ref: version,
                                    git_accessor: version_control_system)
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
            archive_menu: config.archive_menu,
        }

        optional_arguments = {}
        optional_arguments.merge!(template_variables: config.template_variables) if config.respond_to?(:template_variables)
        if publishing_to_github? location
          config.versions.each { |version| arguments[:sections].concat sections_from version, version_control_system }
          optional_arguments.merge!(versions: config.versions)
        end

        arguments.merge! optional_arguments
      end

      def sections_from(version, version_control_system)
        config_file = File.join book_checkout(version, version_control_system), 'config.yml'
        attrs       = YAML.load(File.read(config_file))['sections']
        raise VersionUnsupportedError.new(version) if attrs.nil?

        attrs.map do |section_hash|
          section_hash['repository']['ref'] = version
          section_hash['directory'] = File.join(version, section_hash['directory'])
          section_hash
        end
      end

      def book_checkout(ref, version_control_system)
        temp_workspace = Dir.mktmpdir('book_checkout')
        book = Book.from_remote(logger: logger,
                                full_name: config.book_repo,
                                destination_dir: temp_workspace,
                                ref: ref,
                                git_accessor: version_control_system,
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

      def dita_transform_script(path_to_dita_ot_library)
        <<SCRIPT
<?xml version="1.0" encoding="UTF-8" ?>
<project name="dita_transform_script" default="somebuild" basedir=".">

    <property name="dita.dir" location="src/main"/>

    <target name="somebuild">
        <ant antfile="#{path_to_dita_ot_library}/build.xml">
            <property name="args.input" value="${dita_location}" />
            <property name="transtype" value="htmlhelp"/>
            <property name="out" value="${out_dir}" />
        </ant>
    </target>

</project>
SCRIPT
      end
    end
  end
end
