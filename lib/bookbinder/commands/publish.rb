module Bookbinder
  class Cli
    class Publish < BookbinderCommand
      def run(cli_arguments)
        raise Cli::InvalidArguments unless arguments_are_valid?(cli_arguments)

        target_tag    = (cli_arguments[1..-1] - ['--verbose']).pop
        final_app_dir = File.absolute_path('final_app')

        bind_book(cli_arguments, final_app_dir, target_tag)
      end

      def self.usage
        "<local|github> [tag] [--verbose]"
      end

      private

      def bind_book(cli_arguments, final_app_dir, target_tag)
        if target_tag
          checkout_book_at(target_tag) { generate_site_etc(cli_arguments, final_app_dir, target_tag) }
        else
          generate_site_etc(cli_arguments, final_app_dir)
        end
      end

      def generate_site_etc(cli_args, final_app_dir, target_tag=nil)
        # TODO: general solution to turn all string keys to symbols
        verbosity = cli_args.include?('--verbose')
        location = cli_args[0]

        success = Publisher.new(@logger).publish publication_arguments(verbosity, location, pdf_options, target_tag, final_app_dir)
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

      def publication_arguments(verbosity, location, pdf_hash, target_tag, final_app_dir)
        local_repo_dir = location == 'local' ? File.absolute_path('..') : nil
        git_mod_cache = GitModCache.new(File.absolute_path('file_modification_dates'), location=='local')

        arguments = {
            sections: sections,
            output_dir: File.absolute_path('output'),
            master_middleman_dir: layout_repo_path(local_repo_dir),
            final_app_dir: final_app_dir,
            pdf: pdf_hash,
            verbose: verbosity,
            pdf_index: config.pdf_index,
            local_repo_dir: local_repo_dir,
            file_cache: git_mod_cache
        }

        arguments.merge!(template_variables: config.template_variables) if config.respond_to?(:template_variables)
        arguments.merge!(host_for_sitemap: config.public_host)
        arguments.merge!(target_tag: target_tag) if target_tag
        arguments
      end

      def sections
        result = config.sections

        if config.has_option?('versions')
          config.versions.each { |version| result.concat sections_from version }
        end

        result
      end

      def sections_from(version)
        config_file = File.join book_checkout(version), 'config.yml'
        attrs       = YAML.load(File.read(config_file))['sections']

        attrs.map do |section_hash|
          section_hash['repository']['ref'] = version
          section_hash['directory'] = File.join(version, section_hash['directory'])
          section_hash
        end
      end

      def book_checkout(ref)
        temp_workspace = Dir.mktmpdir
        book = Book.from_remote(logger: @logger, full_name: config.book_repo,
                                destination_dir: temp_workspace, ref: ref)

        File.join temp_workspace, book.directory
      end

      def layout_repo_path(local_repo_dir)
        if config.has_option?('layout_repo')
          if local_repo_dir
            File.join(local_repo_dir, config.layout_repo.split('/').last)
          else
            section = {'repository' => {'name' => config.layout_repo}}
            destination_dir = Dir.mktmpdir
            repository =  Repository.build_from_remote(@logger, section, destination_dir, 'master')
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
    end
  end
end