class Cli
  class Publish < BookbinderCommand
    def run(cli_arguments)
      raise Cli::InvalidArguments unless arguments_are_valid?(cli_arguments)

      target_tag    = (cli_arguments[1..-1] - ['--verbose']).pop
      final_app_dir = File.absolute_path('final_app')

      if target_tag
        checkout_book_at(target_tag) do
          generate_site_and_pdf_for(cli_args:       cli_arguments,
                                    target_tag:     target_tag,
                                    final_app_dir:  final_app_dir)
        end
      else
        generate_site_and_pdf_for(cli_args: cli_arguments, final_app_dir: final_app_dir)
      end
    end

    def self.usage
      "<local|github> [tag] [--verbose]"
    end

    private

    def generate_site_and_pdf_for(cli_args: {}, target_tag: nil, final_app_dir: nil)
      # TODO: general solution to turn all string keys to symbols
      pdf_hash = config['pdf'] ? {page: config['pdf']['page'],
                                  filename: config['pdf']['filename'],
                                  header: config['pdf']['header']}
      : nil

      verbosity = cli_args.include?('--verbose')
      location = cli_args[0]

      success = Publisher.new.publish publication_arguments(verbosity, location, pdf_hash, target_tag, final_app_dir)
      success ? 0 : 1
    end

    def checkout_book_at(target_tag, &doc_generation)
      temp_workspace     = Dir.mktmpdir
      initial_config     = YAML.load(File.read('./config.yml'))
      book               = Book.from_remote(full_name: initial_config.fetch('book_repo'),
                                            destination_dir: temp_workspace, ref: target_tag)
      expected_book_path = File.join temp_workspace, book.directory

      log "Binding \"#{book.short_name.cyan}\" at #{target_tag.magenta}"
      FileUtils.chdir(expected_book_path) { doc_generation.call(config, target_tag) }
    end

    def publication_arguments(verbosity, location, pdf_hash, target_tag, final_app_dir)
      arguments = {
          repos: config.fetch('repos'),
          output_dir: File.absolute_path('output'),
          master_middleman_dir: File.absolute_path('master_middleman'),
          final_app_dir: final_app_dir,
          pdf: pdf_hash,
          verbose: verbosity
      }

      arguments.merge!(local_repo_dir: File.absolute_path('..')) if location == 'local'
      arguments.merge!(template_variables: config.fetch('template_variables')) if config.has_key?('template_variables')
      arguments.merge!(host_for_sitemap: config.fetch('public_host'))
      arguments.merge!(target_tag: target_tag) if target_tag
      arguments
    end

    def arguments_are_valid?(arguments)
      verbose           = arguments[1..-1].include?('--verbose')
      tag_provided      = (arguments[1..-1] - ['--verbose']).any?
      nothing_special   = arguments[1..-1].empty?

      %w(local github).include?(arguments[0]) && (tag_provided or verbose or nothing_special)
    end
  end
end
