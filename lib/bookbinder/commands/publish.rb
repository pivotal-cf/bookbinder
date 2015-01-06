require_relative '../book'
require_relative '../cli_exceptions'
require_relative '../configuration'
require_relative '../directory_helpers'
require_relative '../middleman_runner'
require_relative '../publisher'
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

      def run(cli_arguments, git_accessor=Git)
        raise CliError::InvalidArguments unless arguments_are_valid?(cli_arguments)
        @git_accessor = git_accessor

        target_tag    = (cli_arguments[1..-1] - ['--verbose']).pop
        final_app_dir = File.absolute_path('final_app')
        bind_book(cli_arguments, final_app_dir, target_tag)
      end

      private

      def bind_book(cli_arguments, final_app_dir, target_tag)
        if target_tag
          @logger.warn "[WARNING] You are publishing from a tag. The `tag` parameter is deprecated and will be removed in a future release."

          checkout_book_at(target_tag) { generate_site_etc(cli_arguments, final_app_dir, target_tag) }
        else
          generate_site_etc(cli_arguments, final_app_dir)
        end
      end

      def generate_site_etc(cli_args, final_app_dir, target_tag=nil)
        # TODO: general solution to turn all string keys to symbols
        verbosity = cli_args.include?('--verbose')
        location = cli_args[0]

        cli_options = { verbose: verbosity, target_tag: target_tag }
        output_paths = output_directory_paths(location, final_app_dir)
        publish_config = publish_config(location)
        spider = Spider.new(@logger, app_dir: final_app_dir)
        static_site_generator = MiddlemanRunner.new(@logger)

        success = Publisher.new(@logger, spider, static_site_generator).publish(cli_options, output_paths, publish_config, @git_accessor)
        success ? 0 : 1
      end

      def pdf_options
        return unless config.has_option?('pdf')
        {
            page: config.pdf['page'],
            filename: config.pdf['filename'],
            header: config.pdf.fetch('header')
        }
      end

      def checkout_book_at(target_tag)
        @logger.log "Binding #{config.book_repo.cyan} at #{target_tag.magenta}"
        FileUtils.chdir(book_checkout(target_tag)) { refresh_config; yield }
      end

      def refresh_config
        hash = YAML.load(File.read('./config.yml'))
        hash['pdf_index'] = nil
        @config = Configuration.new(@logger, hash)
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
            pdf: pdf_options,
            pdf_index: config.pdf_index,
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
            repository =  GitHubRepository.build_from_remote(@logger, section, destination_dir, 'master', @git_accessor)
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
    end
  end
end
